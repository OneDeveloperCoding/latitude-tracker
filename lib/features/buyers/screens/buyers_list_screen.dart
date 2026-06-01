import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../sales/models/sale.dart';
import '../../sales/repositories/sale_repository.dart';
import '../models/buyer.dart';
import '../models/buyer_stats.dart';
import '../repositories/buyer_repository.dart';
import 'buyer_detail_screen.dart';
import 'buyer_form_screen.dart';

enum _SortMode { alphabetical, lastPurchase, ranking }

enum _RankingMetric { totalSpent, frequency, averageOrder, unpaidBalance }

extension _RankingMetricLabel on _RankingMetric {
  String get label => switch (this) {
        _RankingMetric.totalSpent => 'Total spent',
        _RankingMetric.frequency => 'Most orders',
        _RankingMetric.averageOrder => 'Avg order',
        _RankingMetric.unpaidBalance => 'Unpaid',
      };
}

class _BuyerWithStats {
  final Buyer buyer;
  final BuyerStats stats;

  const _BuyerWithStats({required this.buyer, required this.stats});

  // Proxy getters so tile widgets don't need to know about the stats nesting.
  DateTime? get lastPurchaseAt => stats.lastPurchaseAt;
  int get saleCount => stats.saleCount;
  double get totalPaid => stats.totalPaid;
  double get unpaidBalance => stats.unpaidBalance;
  double get averageOrderValue => stats.averageOrderValue;

  double metricValue(_RankingMetric metric) => switch (metric) {
        _RankingMetric.totalSpent => stats.totalPaid,
        _RankingMetric.frequency => stats.saleCount.toDouble(),
        _RankingMetric.averageOrder => stats.averageOrderValue,
        _RankingMetric.unpaidBalance => stats.unpaidBalance,
      };
}

class BuyersListScreen extends StatefulWidget {
  const BuyersListScreen({super.key});

  @override
  State<BuyersListScreen> createState() => _BuyersListScreenState();
}

class _BuyersListScreenState extends State<BuyersListScreen> {
  final _buyerRepo = BuyerRepository();
  final _saleRepo = SaleRepository();

  late StreamSubscription<List<Buyer>> _buyersSub;
  late StreamSubscription<List<Sale>> _salesSub;

  List<Buyer> _buyers = [];
  List<Sale> _sales = [];
  bool _loading = true;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.alphabetical;
  _RankingMetric _rankingMetric = _RankingMetric.totalSpent;

  @override
  void initState() {
    super.initState();
    _buyersSub = _buyerRepo.watchBuyers().listen((buyers) {
      setState(() {
        _buyers = buyers;
        _loading = false;
      });
    });
    _salesSub = _saleRepo.watchSales().listen((sales) {
      setState(() => _sales = sales);
    });
  }

  @override
  void dispose() {
    _buyersSub.cancel();
    _salesSub.cancel();
    _searchController.dispose();
    super.dispose();
  }

  _BuyerWithStats _statsFor(Buyer buyer) {
    final buyerSales = _sales.where((s) => s.buyerId == buyer.id).toList();
    return _BuyerWithStats(
      buyer: buyer,
      stats: BuyerStats.compute(buyerSales),
    );
  }

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

  List<Object> _buildAlphabeticalItems() {
    return _applySearch(_buyers).map(_statsFor).toList();
  }

  List<Object> _buildGroupedItems() {
    final stats = _applySearch(_buyers).map(_statsFor).toList();
    final withPurchase = stats.where((s) => s.lastPurchaseAt != null).toList()
      ..sort((a, b) => b.lastPurchaseAt!.compareTo(a.lastPurchaseAt!));
    final noPurchase = stats.where((s) => s.lastPurchaseAt == null).toList()
      ..sort((a, b) => a.buyer.name.compareTo(b.buyer.name));

    final groups = <String, List<_BuyerWithStats>>{};
    for (final s in withPurchase) {
      final label = DateFormat('MMMM yyyy').format(s.lastPurchaseAt!);
      groups.putIfAbsent(label, () => []).add(s);
    }

    final items = <Object>[];
    for (final entry in groups.entries) {
      items.add(entry.key);
      items.addAll(entry.value);
    }
    if (noPurchase.isNotEmpty) {
      items.add('Never purchased');
      items.addAll(noPurchase);
    }
    return items;
  }

  List<_BuyerWithStats> _buildRankedItems() {
    return (_applySearch(_buyers).map(_statsFor).toList()
          ..sort((a, b) =>
              b.metricValue(_rankingMetric)
                  .compareTo(a.metricValue(_rankingMetric))))
        .toList();
  }

  void _openBuyer(Buyer buyer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuyerDetailScreen(buyerId: buyer.id)),
    );
  }

  void _showSortMenu() async {
    final selected = await showModalBottomSheet<_SortMode>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Alphabetical'),
              selected: _sortMode == _SortMode.alphabetical,
              onTap: () => Navigator.pop(context, _SortMode.alphabetical),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Group by last purchase'),
              selected: _sortMode == _SortMode.lastPurchase,
              onTap: () => Navigator.pop(context, _SortMode.lastPurchase),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Buyer ranking'),
              selected: _sortMode == _SortMode.ranking,
              onTap: () => Navigator.pop(context, _SortMode.ranking),
            ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _sortMode = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Change view',
            onPressed: _showSortMenu,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BuyerFormScreen()),
        ),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search buyers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (_sortMode == _SortMode.ranking) _RankingMetricBar(
            selected: _rankingMetric,
            onSelected: (m) => setState(() => _rankingMetric = m),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_sortMode == _SortMode.ranking) {
      final ranked = _buildRankedItems();
      if (ranked.isEmpty) {
        return Center(
          child: Text(_searchQuery.isEmpty
              ? 'No buyers yet. Tap + to add one.'
              : 'No buyers match "$_searchQuery".'),
        );
      }
      return ListView.builder(
        itemCount: ranked.length,
        itemBuilder: (context, index) => _RankedBuyerTile(
          stats: ranked[index],
          rank: index + 1,
          metric: _rankingMetric,
          onTap: () => _openBuyer(ranked[index].buyer),
        ),
      );
    }

    final items = _sortMode == _SortMode.alphabetical
        ? _buildAlphabeticalItems()
        : _buildGroupedItems();

    if (items.isEmpty) {
      return Center(
        child: Text(_searchQuery.isEmpty
            ? 'No buyers yet. Tap + to add one.'
            : 'No buyers match "$_searchQuery".'),
      );
    }

    return ListView.builder(
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
  final ValueChanged<_RankingMetric> onSelected;

  const _RankingMetricBar({required this.selected, required this.onSelected});

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
              label: Text(metric.label),
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

    return ListTile(
      leading: CircleAvatar(child: Text(buyer.name[0].toUpperCase())),
      title: Text(buyer.name),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
          if (stats.saleCount > 0)
            Text(
              '${stats.saleCount} sale${stats.saleCount == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
      onTap: onTap,
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
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final buyer = stats.buyer;

    final Color rankColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => Theme.of(context).colorScheme.surfaceContainerHighest,
    };

    final String primaryValue = switch (metric) {
      _RankingMetric.totalSpent => currency.format(stats.totalPaid),
      _RankingMetric.frequency =>
        '${stats.saleCount} sale${stats.saleCount == 1 ? '' : 's'}',
      _RankingMetric.averageOrder => currency.format(stats.averageOrderValue),
      _RankingMetric.unpaidBalance => currency.format(stats.unpaidBalance),
    };

    final String secondaryValue = switch (metric) {
      _RankingMetric.totalSpent =>
        '${stats.saleCount} sale${stats.saleCount == 1 ? '' : 's'}',
      _RankingMetric.frequency => currency.format(stats.totalPaid),
      _RankingMetric.averageOrder =>
        '${stats.saleCount} sale${stats.saleCount == 1 ? '' : 's'}',
      _RankingMetric.unpaidBalance =>
        '${stats.saleCount} sale${stats.saleCount == 1 ? '' : 's'}',
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: rankColor,
        child: Text(
          '$rank',
          style: TextStyle(
            color: rank <= 3 ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(buyer.name),
      subtitle: buyer.instagramHandle != null
          ? Text('@${buyer.instagramHandle}')
          : buyer.phone != null
              ? Text(buyer.phone!)
              : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            primaryValue,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            secondaryValue,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
