import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/buyers_store.dart';
import '../../../core/store/sales_store.dart';
import '../../sales/services/sale_grouper.dart';
import '../models/buyer.dart';
import '../models/buyer_stats.dart';
import 'buyer_detail_screen.dart';
import 'buyer_form_screen.dart';

enum _SortMode { alphabetical, lastPurchase, ranking }

enum _RankingMetric { totalSpent, frequency, averageSale, unpaidBalance }

class _BuyerWithStats {
  final Buyer buyer;
  final BuyerStats stats;

  const _BuyerWithStats({required this.buyer, required this.stats});

  DateTime? get lastPurchaseAt => stats.lastPurchaseAt;
  int get saleCount => stats.saleCount;
  double get totalPaid => stats.totalPaid;
  double get unpaidBalance => stats.unpaidBalance;
  double get averageSaleValue => stats.averageSaleValue;

  double metricValue(_RankingMetric metric) => switch (metric) {
        _RankingMetric.totalSpent => stats.totalPaid,
        _RankingMetric.frequency => stats.saleCount.toDouble(),
        _RankingMetric.averageSale => stats.averageSaleValue,
        _RankingMetric.unpaidBalance => stats.unpaidBalance,
      };
}

class BuyersListScreen extends StatefulWidget {
  const BuyersListScreen({super.key});

  @override
  State<BuyersListScreen> createState() => _BuyersListScreenState();
}

class _BuyersListScreenState extends State<BuyersListScreen> {
  bool get _loading =>
      BuyersStore.current == null || SalesStore.current == null;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchExpanded = false;
  _SortMode _sortMode = _SortMode.alphabetical;
  _RankingMetric _rankingMetric = _RankingMetric.totalSpent;

  // Stats cache: rebuilt only when stores change (O(n×m) work).
  var _statsCache = <String, _BuyerWithStats>{};

  // View caches: rebuilt when stats, search query, sort mode, or metric change.
  List<Object> _alphabeticalCache = [];
  List<Object> _groupedCache = [];
  List<_BuyerWithStats> _rankedCache = [];

  @override
  void initState() {
    super.initState();
    BuyersStore.state.addListener(_onStoreChanged);
    SalesStore.state.addListener(_onStoreChanged);
    _rebuildStats();
    // Views require context.s — deferred to first build via _rebuildViews().
  }

  void _rebuildStats() {
    final byBuyer = SaleGrouper.byBuyerId(SalesStore.current ?? []);
    _statsCache = {
      for (final buyer in BuyersStore.current ?? [])
        buyer.id: _BuyerWithStats(
          buyer: buyer,
          stats: BuyerStats.compute(byBuyer[buyer.id] ?? []),
        ),
    };
  }

  void _rebuildViews() {
    _alphabeticalCache =
        _applySearch(BuyersStore.current ?? []).map(_statsFor).toList();
    _groupedCache = _computeGroupedItems();
    _rankedCache = _applySearch(BuyersStore.current ?? [])
        .map(_statsFor)
        .toList()
      ..sort((a, b) =>
          b.metricValue(_rankingMetric).compareTo(a.metricValue(_rankingMetric)));
  }

  void _onStoreChanged() {
    _rebuildStats();
    _rebuildViews();
    setState(() {});
  }

  @override
  void dispose() {
    BuyersStore.state.removeListener(_onStoreChanged);
    SalesStore.state.removeListener(_onStoreChanged);
    _searchController.dispose();
    super.dispose();
  }

  _BuyerWithStats _statsFor(Buyer buyer) =>
      _statsCache[buyer.id] ??
      _BuyerWithStats(buyer: buyer, stats: BuyerStats.compute([]));

  List<Buyer> _applySearch(List<Buyer> buyers) {
    if (_searchQuery.isEmpty) return buyers;
    final query = _searchQuery.toLowerCase();
    return buyers
        .where((b) =>
            b.name.toLowerCase().contains(query) ||
            (b.instagramHandle?.toLowerCase().contains(query) ?? false) ||
            (b.phone?.contains(query) ?? false))
        .toList();
  }

  List<Object> _computeGroupedItems() {
    final neverPurchasedLabel = context.s.neverPurchased;
    final stats = _applySearch(BuyersStore.current ?? []).map(_statsFor).toList();
    final withPurchase = stats.where((s) => s.lastPurchaseAt != null).toList()
      ..sort((a, b) => b.lastPurchaseAt!.compareTo(a.lastPurchaseAt!));
    final noPurchase = stats.where((s) => s.lastPurchaseAt == null).toList()
      ..sort((a, b) => a.buyer.name.compareTo(b.buyer.name));

    final groups = <String, List<_BuyerWithStats>>{};
    for (final stat in withPurchase) {
      final label = DateFormat('MMMM yyyy').format(stat.lastPurchaseAt!);
      groups.putIfAbsent(label, () => []).add(stat);
    }

    final items = <Object>[];
    for (final entry in groups.entries) {
      items.add(entry.key);
      items.addAll(entry.value);
    }
    if (noPurchase.isNotEmpty) {
      items.add(neverPurchasedLabel);
      items.addAll(noPurchase);
    }
    return items;
  }

  void _openBuyer(Buyer buyer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuyerDetailScreen(buyerId: buyer.id)),
    );
  }

  void _showSortMenu() {
    final s = context.s;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: Text(s.alphabetical),
                selected: _sortMode == _SortMode.alphabetical,
                onTap: () {
                  _sortMode = _SortMode.alphabetical;
                  _rebuildViews();
                  setState(() {});
                  setSheetState(() {});
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text(s.groupByLastPurchase),
                selected: _sortMode == _SortMode.lastPurchase,
                onTap: () {
                  _sortMode = _SortMode.lastPurchase;
                  _rebuildViews();
                  setState(() {});
                  setSheetState(() {});
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events),
                title: Text(s.buyerRanking),
                selected: _sortMode == _SortMode.ranking,
                onTap: () {
                  _sortMode = _SortMode.ranking;
                  _rebuildViews();
                  setState(() {});
                  setSheetState(() {});
                },
              ),
              if (_sortMode == _SortMode.ranking) ...[
                const Divider(height: 1),
                _RankingMetricBar(
                  selected: _rankingMetric,
                  metricLabel: _metricLabel,
                  onSelected: (m) {
                    _rankingMetric = m;
                    _rebuildViews();
                    setState(() {});
                    setSheetState(() {});
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _metricLabel(_RankingMetric metric) {
    final s = context.s;
    return switch (metric) {
      _RankingMetric.totalSpent => s.totalSpentMetric,
      _RankingMetric.frequency => s.mostSalesMetric,
      _RankingMetric.averageSale => s.avgSaleMetric,
      _RankingMetric.unpaidBalance => s.unpaidBalanceMetric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BuyerFormScreen()),
        ),
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                if (_searchExpanded)
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: s.searchBuyers,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _rebuildViews();
                            setState(() => _searchExpanded = false);
                          },
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        _searchQuery = value;
                        _rebuildViews();
                        setState(() {});
                      },
                    ),
                  )
                else ...[
                  FilterChip(
                    avatar: const Icon(Icons.search, size: 18),
                    label: Text(s.searchBuyers),
                    selected: false,
                    onSelected: (_) => setState(() => _searchExpanded = true),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                ],
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: s.changeView,
                  onPressed: _showSortMenu,
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      ),
    );
  }

  Widget _buildBody() {
    final s = context.s;
    if (_loading) return const Center(child: CircularProgressIndicator());

    // Populate view caches on first build (initState has no context).
    if (_alphabeticalCache.isEmpty && _groupedCache.isEmpty &&
        _rankedCache.isEmpty && (BuyersStore.current?.isNotEmpty ?? false)) {
      _rebuildViews();
    }

    if (_sortMode == _SortMode.ranking) {
      if (_rankedCache.isEmpty) {
        return Center(child: Text(s.noBuyersYet(_searchQuery)));
      }
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(
            12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
        itemCount: _rankedCache.length,
        itemBuilder: (context, index) => _RankedBuyerTile(
          stats: _rankedCache[index],
          rank: index + 1,
          metric: _rankingMetric,
          onTap: () => _openBuyer(_rankedCache[index].buyer),
        ),
      );
    }

    final items = _sortMode == _SortMode.alphabetical
        ? _alphabeticalCache
        : _groupedCache;

    if (items.isEmpty) {
      return Center(child: Text(s.noBuyersYet(_searchQuery)));
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
            12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) return _SectionHeader(label: item);
        final stats = item as _BuyerWithStats;
        return _BuyerTile(
          stats: stats,
          sortMode: _sortMode,
          onTap: () => _openBuyer(stats.buyer),
        );
      },
    );
  }
}

class _RankingMetricBar extends StatelessWidget {
  final _RankingMetric selected;
  final String Function(_RankingMetric) metricLabel;
  final ValueChanged<_RankingMetric> onSelected;

  const _RankingMetricBar({
    required this.selected,
    required this.metricLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: _RankingMetric.values.map((metric) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(metricLabel(metric)),
              selected: selected == metric,
              onSelected: (_) => onSelected(metric),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _BuyerTile extends StatelessWidget {
  final _BuyerWithStats stats;
  final _SortMode sortMode;
  final VoidCallback onTap;

  const _BuyerTile({
    required this.stats,
    required this.sortMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final buyer = stats.buyer;
    final lastPurchase = stats.lastPurchaseAt;

    String? subtitle;
    if (buyer.instagramHandle != null) {
      subtitle = '@${buyer.instagramHandle}';
    } else if (buyer.phone != null) {
      subtitle = buyer.phone;
    }

    final dateLabel = lastPurchase != null
        ? DateFormat('MMM yyyy').format(lastPurchase)
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                  child: Text(buyer.name.isNotEmpty
                      ? buyer.name[0].toUpperCase()
                      : '?')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyer.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    if (buyer.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: buyer.tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(dateLabel,
                      style: Theme.of(context).textTheme.bodySmall),
                  if (stats.saleCount > 0)
                    Text(
                      s.nSales(stats.saleCount),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankedBuyerTile extends StatelessWidget {
  final _BuyerWithStats stats;
  final int rank;
  final _RankingMetric metric;
  final VoidCallback onTap;

  const _RankedBuyerTile({
    required this.stats,
    required this.rank,
    required this.metric,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final buyer = stats.buyer;

    final Color rankColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => Theme.of(context).colorScheme.surfaceContainerHighest,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: rankColor,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rank <= 3
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyer.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (buyer.instagramHandle != null)
                      Text(
                        '@${buyer.instagramHandle}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      )
                    else if (buyer.phone != null)
                      Text(
                        buyer.phone!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _primaryValue(currency, s),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _secondaryValue(currency, s),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _primaryValue(NumberFormat currency, AppStrings s) => switch (metric) {
        _RankingMetric.totalSpent => currency.format(stats.totalPaid),
        _RankingMetric.frequency => s.nSales(stats.saleCount),
        _RankingMetric.averageSale => currency.format(stats.averageSaleValue),
        _RankingMetric.unpaidBalance => currency.format(stats.unpaidBalance),
      };

  String _secondaryValue(NumberFormat currency, AppStrings s) => switch (metric) {
        _RankingMetric.totalSpent => s.nSales(stats.saleCount),
        _RankingMetric.frequency => currency.format(stats.totalPaid),
        _RankingMetric.averageSale => s.nSales(stats.saleCount),
        _RankingMetric.unpaidBalance => s.nSales(stats.saleCount),
      };
}
