import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/store/buyers_store.dart';
import '../../../core/store/sales_store.dart';
import '../../buyers/models/buyer.dart';
import '../../heat_map/screens/heat_map_screen.dart';
import '../models/sale.dart';
import '../models/sale_filter.dart';
import '../services/sale_grouper.dart';
import '../services/sale_urgency.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

class SalesListScreen extends StatefulWidget {
  final Set<SaleFilter> initialFilters;

  const SalesListScreen({
    super.key,
    this.initialFilters = const <SaleFilter>{},
  });

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

enum _SortOrder { newestFirst, oldestFirst, priceHigh, priceLow }

class _SalesListScreenState extends State<SalesListScreen> {
  Set<SaleFilter> _activeFilters = {};
  Set<String> _categoryFilters = {};
  int? _selectedYear;
  int? _selectedMonth;
  Buyer? _buyerFilter;
  _SortOrder _sortOrder = _SortOrder.newestFirst;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  Sale? _selectedSale;
  final _rightPanelKey = GlobalKey<NavigatorState>();

  // Cached once per store/filter/sort/search change — not on every build().
  List<Sale> _filteredSales = [];
  Map<String, List<Sale>> _groupedSales = {};

  bool get _loading => SalesStore.current == null;

  // Counts active filter constraints for the tune-icon badge.
  // Sort is excluded — it has its own badge on the sort button.
  int get _activeFilterCount =>
      _activeFilters.length +
      _categoryFilters.length +
      (_selectedYear != null ? 1 : 0) +
      (_buyerFilter != null ? 1 : 0);

  // Years that have at least one Sale, newest first.
  List<int> get _availableYears {
    final years = (SalesStore.current ?? [])
        .map((s) => s.createdAt.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  // Months (1–12) in [year] that have at least one Sale, chronological.
  List<int> _availableMonths(int year) {
    final months = (SalesStore.current ?? [])
        .where((s) => s.createdAt.year == year)
        .map((s) => s.createdAt.month)
        .toSet()
        .toList()
      ..sort();
    return months;
  }

  String _monthLabel(int month) =>
      DateFormat('MMM').format(DateTime(2000, month));

  @override
  void initState() {
    super.initState();
    _activeFilters = Set<SaleFilter>.from(widget.initialFilters);
    SalesStore.state.addListener(_onStoreChanged);
    _rebuildCache();
  }

  void _onStoreChanged() {
    _rebuildCache();
    setState(() {});
  }

  void _rebuildCache() {
    var sales = _applyFilter(SalesStore.current ?? []);
    sales = _applySearch(sales);
    sales = _applySort(sales);
    _filteredSales = sales;
    // Historical mode: group by creation month so the grouping matches the
    // year/month filter. Active queue: group by scheduled/creation date.
    _groupedSales = _selectedYear != null
        ? SaleGrouper.byCreatedMonth(sales)
        : SaleGrouper.byWeek(sales);
  }

  @override
  void dispose() {
    SalesStore.state.removeListener(_onStoreChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<Sale> _applyFilter(List<Sale> sales) {
    var result = List<Sale>.from(sales);

    // Active-only default: hide delivered unless a year is explicitly selected.
    if (_selectedYear == null) {
      result = result
          .where((s) => s.shipment.status != ShipmentStatus.delivered)
          .toList();
    }

    // Year + optional month scope. Selecting a year lifts the delivered default.
    if (_selectedYear != null) {
      result =
          result.where((s) => s.createdAt.year == _selectedYear).toList();
      if (_selectedMonth != null) {
        result = result
            .where((s) => s.createdAt.month == _selectedMonth)
            .toList();
      }
    }

    if (_buyerFilter != null) {
      result =
          result.where((s) => s.buyerId == _buyerFilter!.id).toList();
    }

    if (_categoryFilters.isNotEmpty) {
      result = result
          .where((s) => s.items.any((i) => _categoryFilters.contains(i.category)))
          .toList();
    }

    if (_activeFilters.isNotEmpty) {
      final now = DateTime.now();
      result = result
          .where((s) => testSaleFilters(s, _activeFilters, now: now))
          .toList();
    }

    return result;
  }

  List<Sale> _applySearch(List<Sale> sales) {
    if (_searchQuery.isEmpty) return sales;
    final q = _searchQuery.toLowerCase();
    return sales
        .where((s) =>
            s.buyerName.toLowerCase().contains(q) ||
            s.items.any((i) => i.description.toLowerCase().contains(q)))
        .toList();
  }

  List<Sale> _applySort(List<Sale> sales) {
    if (_sortOrder == _SortOrder.newestFirst) return sales;
    final sorted = List<Sale>.from(sales);
    switch (_sortOrder) {
      case _SortOrder.oldestFirst:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortOrder.priceHigh:
        sorted.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
      case _SortOrder.priceLow:
        sorted.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
      case _SortOrder.newestFirst:
        break;
    }
    return sorted;
  }

  String _sortOrderLabel(_SortOrder order) {
    final s = context.s;
    return switch (order) {
      _SortOrder.newestFirst => s.newestFirst,
      _SortOrder.oldestFirst => s.oldestFirst,
      _SortOrder.priceHigh => s.priceHighToLow,
      _SortOrder.priceLow => s.priceLowToHigh,
    };
  }

  bool _isTablet() => MediaQuery.sizeOf(context).width >= 600;

  void _selectSale(Sale sale) {
    if (!_isTablet()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SaleDetailScreen(saleId: sale.id)),
      );
      return;
    }
    if (_selectedSale?.id == sale.id) return;
    setState(() => _selectedSale = sale);
    final nav = _rightPanelKey.currentState;
    if (nav != null) {
      nav.popUntil((r) => r.isFirst);
      nav.push(MaterialPageRoute(
        builder: (_) => SaleDetailScreen(saleId: sale.id),
      ));
    }
  }

  void _openNewSale() {
    if (!_isTablet()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NewSaleScreen()),
      );
      return;
    }
    setState(() => _selectedSale = null);
    final nav = _rightPanelKey.currentState;
    if (nav != null) {
      nav.popUntil((r) => r.isFirst);
      nav.push(MaterialPageRoute(builder: (_) => const NewSaleScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final filterCount = _activeFilterCount;
    final isTablet = _isTablet();

    final listPanel = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: s.searchSales,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    _searchQuery = v;
                    _rebuildCache();
                    setState(() {});
                  },
                ),
              ),
              Badge(
                label: filterCount > 0 ? Text('$filterCount') : null,
                isLabelVisible: filterCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: s.moreFilters,
                  onPressed: _showOptionsSheet,
                ),
              ),
              Badge(
                isLabelVisible: _sortOrder != _SortOrder.newestFirst,
                child: PopupMenuButton<_SortOrder>(
                  icon: const Icon(Icons.sort),
                  tooltip: s.sortBy,
                  onSelected: (order) {
                    setState(() => _sortOrder = order);
                    _rebuildCache();
                  },
                  itemBuilder: (_) => _SortOrder.values
                      .map((order) => PopupMenuItem(
                            value: order,
                            child: Row(
                              children: [
                                Text(_sortOrderLabel(order)),
                                if (_sortOrder == order) ...[
                                  const Spacer(),
                                  const Icon(Icons.check, size: 16),
                                ],
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined),
                tooltip: s.viewMap,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HeatMapScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: s.legendTitle,
                onPressed: () => _showPathLegend(context, s),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredSales.isEmpty
                  ? Center(child: Text(s.noSalesFound))
                  : _TimelineView(
                      groups: _groupedSales,
                      selectedSaleId: isTablet ? _selectedSale?.id : null,
                      onSaleTap: _selectSale,
                    ),
        ),
      ],
    );

    final fab = FloatingActionButton(
      heroTag: null,
      onPressed: _openNewSale,
      child: const Icon(Icons.add),
    );

    if (!isTablet) {
      return Scaffold(
        floatingActionButton: fab,
        body: SafeArea(bottom: false, child: listPanel),
      );
    }

    return Scaffold(
      floatingActionButton: fab,
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            SizedBox(width: 360, child: listPanel),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Navigator(
                key: _rightPanelKey,
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) => const _RightPanelPlaceholder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    final s = context.s;
    final years = _availableYears;
    final groups = [
      (
        label: s.dashboardGroupMoney,
        filters: [SaleFilter.unpaid, SaleFilter.overdue],
      ),
      (
        label: s.dashboardGroupLogistics,
        filters: [
          SaleFilter.pendingShipment,
          SaleFilter.assemblyNotReady,
          SaleFilter.shipped,
          SaleFilter.scheduled,
          SaleFilter.pickup,
        ],
      ),
      (
        label: s.dashboardGroupCompliance,
        filters: [SaleFilter.nifRequired],
      ),
    ];

    final buyerSearchController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) {
          void updateFilter(SaleFilter f, bool? checked) {
            _activeFilters = checked == true
                ? {..._activeFilters, f}
                : ({..._activeFilters}..remove(f));
            _rebuildCache();
            setState(() {});
            setSheetState(() {});
          }

          void clearAll() {
            _activeFilters = {};
            _categoryFilters = {};
            _selectedYear = null;
            _selectedMonth = null;
            _buyerFilter = null;
            buyerSearchController.clear();
            _rebuildCache();
            setState(() {});
            setSheetState(() {});
          }

          final hasAnyActive = _activeFilters.isNotEmpty ||
              _categoryFilters.isNotEmpty ||
              _selectedYear != null ||
              _buyerFilter != null;

          final buyerQuery =
              buyerSearchController.text.trim().toLowerCase();
          final buyerResults = buyerQuery.isEmpty
              ? <Buyer>[]
              : (BuyersStore.current ?? [])
                  .where((b) =>
                      b.name.toLowerCase().contains(buyerQuery))
                  .take(6)
                  .toList();

          return SafeArea(
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              builder: (_, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sheet header ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(s.filterSort,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                          ),
                          if (hasAnyActive)
                            TextButton(
                              onPressed: clearAll,
                              child: Text(s.clearAllFilters),
                            ),
                        ],
                      ),
                    ),
                    // ── Year / month drill-down ────────────────────────────
                    if (years.isNotEmpty) ...[
                      if (_selectedYear == null) ...[
                        _SheetSectionLabel(s.year.toUpperCase()),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Wrap(
                            spacing: 8,
                            children: years
                                .map((y) => FilterChip(
                                      label: Text('$y'),
                                      selected: false,
                                      onSelected: (_) {
                                        _selectedYear = y;
                                        _selectedMonth = null;
                                        _rebuildCache();
                                        setState(() {});
                                        setSheetState(() {});
                                      },
                                    ))
                                .toList(),
                          ),
                        ),
                      ] else ...[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(4, 8, 16, 0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () {
                                  _selectedYear = null;
                                  _selectedMonth = null;
                                  _rebuildCache();
                                  setState(() {});
                                  setSheetState(() {});
                                },
                              ),
                              Text(
                                '$_selectedYear',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Wrap(
                            spacing: 8,
                            children: _availableMonths(_selectedYear!)
                                .map((m) => FilterChip(
                                      label:
                                          Text(_monthLabel(m)),
                                      selected: _selectedMonth == m,
                                      onSelected: (_) {
                                        _selectedMonth =
                                            _selectedMonth == m
                                                ? null
                                                : m;
                                        _rebuildCache();
                                        setState(() {});
                                        setSheetState(() {});
                                      },
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                    // ── Category ───────────────────────────────────────────
                    const Divider(height: 24),
                    _SheetSectionLabel(s.categoryFilterHeader.toUpperCase()),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Builder(
                        builder: (_) {
                          final allCats = (SalesStore.current ?? [])
                              .expand((s) => s.items.map((i) => i.category))
                              .toSet()
                              .toList()
                            ..sort();
                          return Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: allCats
                                .map((cat) => FilterChip(
                                      label: Text(cat),
                                      selected:
                                          _categoryFilters.contains(cat),
                                      onSelected: (on) {
                                        _categoryFilters = on
                                            ? {..._categoryFilters, cat}
                                            : ({..._categoryFilters}
                                              ..remove(cat));
                                        _rebuildCache();
                                        setState(() {});
                                        setSheetState(() {});
                                      },
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ),
                    // ── Buyer ──────────────────────────────────────────────
                    const Divider(height: 24),
                    _SheetSectionLabel(s.buyer.toUpperCase()),
                    if (_buyerFilter != null)
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(_buyerFilter!.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _buyerFilter = null;
                            buyerSearchController.clear();
                            _rebuildCache();
                            setState(() {});
                            setSheetState(() {});
                          },
                        ),
                      )
                    else ...[
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: TextField(
                          controller: buyerSearchController,
                          decoration: InputDecoration(
                            hintText: s.searchBuyers,
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      ...buyerResults.map((b) => ListTile(
                            title: Text(b.name),
                            dense: true,
                            onTap: () {
                              _buyerFilter = b;
                              buyerSearchController.clear();
                              _rebuildCache();
                              setState(() {});
                              setSheetState(() {});
                            },
                          )),
                    ],
                    // ── Filter groups ──────────────────────────────────────
                    const Divider(height: 24),
                    ...groups.expand((group) => [
                          _SheetSectionLabel(group.label.toUpperCase()),
                          ...group.filters.map((f) => CheckboxListTile(
                                title: Text(s.filterLabel(f)),
                                value: _activeFilters.contains(f),
                                onChanged: (v) => updateFilter(f, v),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                              )),
                        ]),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

// ── Tablet right-panel placeholder ───────────────────────────────────────────

class _RightPanelPlaceholder extends StatelessWidget {
  const _RightPanelPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          context.s.selectSalePrompt,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

// ── Shared sheet label ────────────────────────────────────────────────────────

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}

// Shows item descriptions (up to 3) plus "and X more" if needed.
class _ItemDescriptions extends StatelessWidget {
  final Sale sale;
  final List<UrgencyReason> reasons;

  const _ItemDescriptions({required this.sale, required this.reasons});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final items = sale.items;
    final shown = items.take(3).toList();
    final overflow = items.length - 3;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...shown.map((item) => Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  )),
              if (overflow > 0)
                Text(
                  s.andXMore(overflow),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
            ],
          ),
        ),
        _AttentionBadges(sale: sale, reasons: reasons),
      ],
    );
  }
}

// Shows one chip per unique category across all SaleItems.
class _CategoryChips extends StatelessWidget {
  final Sale sale;

  const _CategoryChips({required this.sale});

  @override
  Widget build(BuildContext context) {
    final uniqueCategories =
        sale.items.map((i) => i.category).toSet().toList();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: uniqueCategories
          .map((cat) => _CategoryChip(category: cat))
          .toList(),
    );
  }
}

class _TimelineView extends StatelessWidget {
  final Map<String, List<Sale>> groups;
  final String? selectedSaleId;
  final void Function(Sale) onSaleTap;

  const _TimelineView({
    required this.groups,
    required this.onSaleTap,
    this.selectedSaleId,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final keys = groups.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final groupSales = groups[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                s.timelineLabel(key),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...groupSales.map((sale) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _SaleCard(
                    sale: sale,
                    isSelected: sale.id == selectedSaleId,
                    onTap: () => onSaleTap(sale),
                  ),
                )),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}

// Returns blocker reasons for the ⚠️ badge. Empty list = no badge.

class _SaleCard extends StatelessWidget {
  final Sale sale;
  final bool isSelected;
  final VoidCallback onTap;

  const _SaleCard({
    required this.sale,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final reasons = sale.urgencyReasons();
    final accentColor = reasons.isEmpty
        ? null
        : sale.urgencyLevel() == UrgencyLevel.overdue
            ? Theme.of(context).colorScheme.error
            : Colors.amber[700]!;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: accentColor != null
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: accentColor, width: 4),
                  ),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      sale.buyerName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '€${sale.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              _ItemDescriptions(sale: sale, reasons: reasons),
              const SizedBox(height: 4),
              _CategoryChips(sale: sale),
              Row(
                children: [
                  Text(
                    dateFormat.format(sale.createdAt),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 6),
                  _AgeLabel(sale: sale),
                  const Spacer(),
                  if (sale.scheduledDate != null)
                    _ScheduledDateLabel(sale: sale),
                ],
              ),
              Column(
                children: [
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _SaleProgressPath(sale: sale),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionBadges extends StatelessWidget {
  final Sale sale;
  final List<UrgencyReason> reasons;

  const _AttentionBadges({required this.sale, required this.reasons});

  @override
  Widget build(BuildContext context) {
    final buyerNif = (BuyersStore.current ?? [])
        .where((b) => b.id == sale.buyerId)
        .firstOrNull
        ?.nif;
    final buyerHasNif = buyerNif != null && buyerNif.isNotEmpty;
    final isPaid = sale.payment.status == PaymentStatus.paid;

    // Show NIF badge when NIF is missing or AT filing is actionable.
    // Hidden only when buyer has NIF but sale is not yet paid (nothing to act on).
    final showNifBadge =
        sale.requiresNif && (!buyerHasNif || isPaid);
    final nifBadgeColor = !buyerHasNif
        ? Colors.orange
        : sale.atSubmissionDone
            ? Colors.green
            : Colors.purple;

    final isReadyButUnpaid =
        sale.derivedAssemblyStatus == AssemblyStatus.ready &&
        sale.payment.status == PaymentStatus.unpaid &&
        sale.shipment.status != ShipmentStatus.delivered;

    final hasNote = sale.notes?.isNotEmpty == true;

    if (!hasNote && !showNifBadge && !isReadyButUnpaid && reasons.isEmpty) {
      return const SizedBox.shrink();
    }

    // Order: note → NIF → ready-but-unpaid → urgency warnings.
    // Warnings are rightmost so they catch the eye first when scanning right-to-left.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasNote) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showNotePreview(context, sale.notes!),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.sticky_note_2_outlined,
                size: 22,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (showNifBadge) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showNifDetail(context, buyerHasNif, sale.atSubmissionDone),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                kNifIcon,
                size: 22,
                color: nifBadgeColor,
              ),
            ),
          ),
        ],
        if (isReadyButUnpaid) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showReadyButUnpaidDetail(context),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.price_check,
                size: 22,
                color: Colors.amber,
              ),
            ),
          ),
        ],
        if (reasons.isNotEmpty) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showUrgencyDetail(context, reasons),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                reasons.length == 1
                    ? reasons.first.icon
                    : Icons.warning_amber_rounded,
                size: 22,
                color: reasons.length == 1
                    ? reasons.first.color
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AgeLabel extends StatelessWidget {
  final Sale sale;

  const _AgeLabel({required this.sale});

  @override
  Widget build(BuildContext context) {
    final days = sale.daysOpen();
    final isDelivered = sale.shipment.status == ShipmentStatus.delivered;

    if (isDelivered || days < 14) return const SizedBox.shrink();

    final (icon, color) = days < 30
        ? (Icons.hourglass_top, Colors.amber[700]!)
        : (Icons.hourglass_bottom, Theme.of(context).colorScheme.error);

    return Icon(icon, size: 14, color: color);
  }
}

class _ScheduledDateLabel extends StatelessWidget {
  final Sale sale;

  const _ScheduledDateLabel({required this.sale});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final days = sale.daysUntilScheduled()!;
    final isDelivered = sale.shipment.status == ShipmentStatus.delivered;

    final Color color;
    if (isDelivered) {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    } else if (days < 0) {
      color = Theme.of(context).colorScheme.error;
    } else if (days <= 2) {
      color = Theme.of(context).colorScheme.error;
    } else if (days <= 3) {
      color = Colors.amber[700]!;
    } else {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    final String label = isDelivered
        ? '📅 ${DateFormat('dd MMM').format(sale.scheduledDate!)}'
        : days < 0
            ? '📅 ${DateFormat('dd MMM').format(sale.scheduledDate!)} (${s.daysOverdue(days.abs())})'
            : days == 0
                ? '📅 ${s.today}'
                : days == 1
                    ? '📅 ${s.tomorrow}'
                    : '📅 ${DateFormat('dd MMM').format(sale.scheduledDate!)}';

    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(color: color, fontWeight: FontWeight.w500),
    );
  }
}

void _showNotePreview(BuildContext context, String notes) {
  final s = context.s;
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sticky_note_2_outlined,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(s.sectionNotes,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ),
  );
}

void _showNifDetail(
    BuildContext context, bool buyerHasNif, bool atSubmissionDone) {
  final s = context.s;
  final String title;
  final String body;
  final Color iconColor;

  if (!buyerHasNif) {
    title = s.noNifOnFile;
    body = s.nifSheetBody;
    iconColor = Colors.orange;
  } else if (atSubmissionDone) {
    title = s.atFiledWithAt;
    body = s.atFiledWithAtBody;
    iconColor = Colors.green;
  } else {
    title = s.nifSheetTitle;
    body = s.nifSheetBody;
    iconColor = Colors.purple;
  }

  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(kNifIcon, color: iconColor),
              const SizedBox(width: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ),
  );
}

void _showReadyButUnpaidDetail(BuildContext context) {
  final s = context.s;
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.price_check, color: Colors.amber),
              const SizedBox(width: 12),
              Text(
                s.readyButUnpaidTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.readyButUnpaidBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

void _showUrgencyDetail(
    BuildContext context, List<UrgencyReason> reasons) {
  final s = context.s;
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.urgencySheetTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...reasons.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(r.icon, size: 20, color: r.color),
                  const SizedBox(width: 12),
                  Text(s.urgencyReasonLabel(r.type),
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showPathLegend(BuildContext context, AppStrings s) {
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.legendTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _LegendRow(Icons.build_outlined, Colors.grey,
              '${s.assemblyLegendHeader}: ${s.assemblyLabel(AssemblyStatus.notStarted)}'),
          _LegendRow(Icons.shopping_bag_outlined, Colors.amber[700]!,
              '${s.assemblyLegendHeader}: ${s.assemblyLabel(AssemblyStatus.waitingForMaterials)}'),
          _LegendRow(Icons.build_outlined, Colors.amber[700]!,
              '${s.assemblyLegendHeader}: ${s.assemblyLabel(AssemblyStatus.inProgress)}'),
          _LegendRow(Icons.build, Colors.green,
              '${s.assemblyLegendHeader}: ${s.assemblyLabel(AssemblyStatus.ready)}'),
          const Divider(height: 20),
          _LegendRow(Icons.payments_outlined, Colors.grey,
              '${s.paymentLegendHeader}: ${s.unpaid}'),
          _LegendRow(Icons.payments, Colors.green,
              '${s.paymentLegendHeader}: ${s.paid}'),
          const Divider(height: 20),
          _LegendRow(Icons.local_shipping_outlined, Colors.grey,
              '${s.shipmentLegendHeader}: ${s.shipmentStatusLabel(ShipmentStatus.pending)}'),
          _LegendRow(Icons.local_shipping, Colors.blue,
              '${s.shipmentLegendHeader}: ${s.shipmentStatusLabel(ShipmentStatus.shipped)}'),
          _LegendRow(Icons.local_shipping, Colors.green,
              '${s.shipmentLegendHeader}: ${s.shipmentStatusLabel(ShipmentStatus.delivered)}'),
          _LegendRow(Icons.store, Colors.green, s.pickupNoShipment),
        ],
      ),
    ),
  );
}

class _LegendRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LegendRow(this.icon, this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _SaleProgressPath extends StatelessWidget {
  final Sale sale;

  const _SaleProgressPath({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _assemblyNode(),
        _line(sale.derivedAssemblyStatus == AssemblyStatus.ready),
        _paymentNode(),
        _line(sale.payment.status == PaymentStatus.paid),
        _shipmentNode(),
      ],
    );
  }

  Widget _assemblyNode() {
    final (icon, color) = switch (sale.derivedAssemblyStatus) {
      AssemblyStatus.notStarted => (Icons.build_outlined, Colors.grey),
      AssemblyStatus.waitingForMaterials =>
        (Icons.shopping_bag_outlined, Colors.amber[700]!),
      AssemblyStatus.inProgress =>
        (Icons.build_outlined, Colors.amber[700]!),
      AssemblyStatus.ready => (Icons.build, Colors.green),
    };
    return _PathNode(icon: icon, color: color);
  }

  Widget _paymentNode() {
    final paid = sale.payment.status == PaymentStatus.paid;
    return _PathNode(
      icon: paid ? Icons.payments : Icons.payments_outlined,
      color: paid ? Colors.green : Colors.grey,
    );
  }

  Widget _shipmentNode() {
    if (sale.shipment.type == DeliveryType.pickup) {
      return _PathNode(icon: Icons.store, color: Colors.green);
    }
    final (icon, color) = switch (sale.shipment.status) {
      ShipmentStatus.pending =>
        (Icons.local_shipping_outlined, Colors.grey),
      ShipmentStatus.shipped => (Icons.local_shipping, Colors.blue),
      ShipmentStatus.delivered => (Icons.local_shipping, Colors.green),
    };
    return _PathNode(icon: icon, color: color);
  }

  Widget _line(bool active) => Expanded(
        child: Container(
          height: 2,
          color: active ? Colors.green : Colors.grey[300],
        ),
      );
}

class _PathNode extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _PathNode({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Center(child: Icon(icon, size: 16, color: color)),
    );
  }
}
