import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/store/buyers_store.dart';
import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/core/widgets/sheet_section_label.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/sales/models/sale_filter.dart';
import 'package:latitude_tracker/features/sales/models/sales_list_filters.dart';

class SalesFilterSheet extends StatefulWidget {
  const SalesFilterSheet({
    required this.filters,
    required this.availableYears,
    required this.monthsByYear,
    required this.onFiltersChanged,
    super.key,
  });

  final SalesListFilters filters;
  final List<int> availableYears;
  final Map<int, List<int>> monthsByYear;
  final ValueChanged<SalesListFilters> onFiltersChanged;

  @override
  State<SalesFilterSheet> createState() => _SalesFilterSheetState();
}

class _SalesFilterSheetState extends State<SalesFilterSheet> {
  late SalesListFilters _filters;
  final _buyerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = widget.filters;
  }

  @override
  void dispose() {
    _buyerSearchController.dispose();
    super.dispose();
  }

  void _update(SalesListFilters updated) {
    setState(() => _filters = updated);
    widget.onFiltersChanged(updated);
  }

  void _clearAll() {
    _buyerSearchController.clear();
    _update(SalesListFilters(
      postalCodePrefix: _filters.postalCodePrefix,
      searchQuery: _filters.searchQuery,
    ));
  }

  bool get _hasAnyActive =>
      _filters.activeFilters.isNotEmpty ||
      _filters.categoryFilters.isNotEmpty ||
      _filters.selectedYear != null ||
      _filters.buyerFilter != null ||
      _filters.sortOrder != SortOrder.newestFirst;

  @override
  Widget build(BuildContext context) {
    final s = context.s;

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
          SaleFilter.handDelivery,
        ],
      ),
      (
        label: s.dashboardGroupCompliance,
        filters: [SaleFilter.nifRequired],
      ),
    ];

    final buyerQuery = _buyerSearchController.text.trim().toLowerCase();
    final buyerResults = buyerQuery.isEmpty
        ? <Buyer>[]
        : BuyersStore.currentOrEmpty
            .where((b) => b.name.toLowerCase().contains(buyerQuery))
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
              // ── Sheet header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.filterSort,
                          style:
                              Theme.of(context).textTheme.titleMedium),
                    ),
                    if (_hasAnyActive)
                      TextButton(
                        onPressed: _clearAll,
                        child: Text(s.clearAllFilters),
                      ),
                  ],
                ),
              ),
              // ── Sort ─────────────────────────────────────────────────
              SheetSectionLabel(s.sortBy.toUpperCase()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    _SortChip(
                      label: s.sortDimensionDate,
                      icon:
                          _filters.sortOrder == SortOrder.oldestFirst
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                      isActive:
                          _filters.sortOrder == SortOrder.oldestFirst,
                      onTap: () => _update(_filters.copyWith(
                        sortOrder:
                            _filters.sortOrder == SortOrder.oldestFirst
                                ? SortOrder.newestFirst
                                : SortOrder.oldestFirst,
                      )),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: s.sortDimensionPrice,
                      icon: _filters.sortOrder == SortOrder.priceHigh
                          ? Icons.arrow_downward
                          : _filters.sortOrder == SortOrder.priceLow
                              ? Icons.arrow_upward
                              : null,
                      isActive:
                          _filters.sortOrder == SortOrder.priceHigh ||
                              _filters.sortOrder == SortOrder.priceLow,
                      onTap: () => _update(_filters.copyWith(
                        sortOrder: switch (_filters.sortOrder) {
                          SortOrder.priceHigh => SortOrder.priceLow,
                          SortOrder.priceLow => SortOrder.newestFirst,
                          _ => SortOrder.priceHigh,
                        },
                      )),
                    ),
                  ],
                ),
              ),
              // ── Year / month drill-down ───────────────────────────────
              if (widget.availableYears.isNotEmpty) ...[
                if (_filters.selectedYear == null) ...[
                  SheetSectionLabel(s.year.toUpperCase()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Wrap(
                      spacing: 8,
                      children: widget.availableYears
                          .map((y) => FilterChip(
                                label: Text('$y'),
                                onSelected: (_) =>
                                    _update(_filters.copyWith(
                                  selectedYear: y,
                                  clearMonth: true,
                                )),
                              ))
                          .toList(),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => _update(_filters.copyWith(
                            clearYear: true,
                            clearMonth: true,
                          )),
                        ),
                        Text(
                          '${_filters.selectedYear}',
                          style:
                              Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Wrap(
                      spacing: 8,
                      children:
                          (widget.monthsByYear[_filters.selectedYear] ??
                                  [])
                              .map((m) => FilterChip(
                                    label: Text(_monthLabel(m)),
                                    selected:
                                        _filters.selectedMonth == m,
                                    onSelected: (_) =>
                                        _update(_filters.copyWith(
                                      selectedMonth:
                                          _filters.selectedMonth == m
                                              ? null
                                              : m,
                                      clearMonth:
                                          _filters.selectedMonth == m,
                                    )),
                                  ))
                              .toList(),
                    ),
                  ),
                ],
              ],
              // ── Category ─────────────────────────────────────────────
              const Divider(height: 24),
              SheetSectionLabel(s.categoryFilterHeader.toUpperCase()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Builder(
                  builder: (_) {
                    final allCats = SalesStore.currentOrEmpty
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
                                selected: _filters.categoryFilters
                                    .contains(cat),
                                onSelected: (on) {
                                  final updated = on
                                      ? {
                                          ..._filters.categoryFilters,
                                          cat,
                                        }
                                      : ({..._filters.categoryFilters}
                                        ..remove(cat));
                                  _update(_filters.copyWith(
                                    categoryFilters: updated,
                                  ));
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
              // ── Buyer ─────────────────────────────────────────────────
              const Divider(height: 24),
              SheetSectionLabel(s.buyer.toUpperCase()),
              if (_filters.buyerFilter != null)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_filters.buyerFilter!.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _buyerSearchController.clear();
                      _update(_filters.copyWith(clearBuyer: true));
                    },
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: TextField(
                    controller: _buyerSearchController,
                    decoration: InputDecoration(
                      hintText: s.searchBuyers,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                ...buyerResults.map((b) => ListTile(
                      title: Text(b.name),
                      dense: true,
                      onTap: () {
                        _buyerSearchController.clear();
                        _update(_filters.copyWith(buyerFilter: b));
                      },
                    )),
              ],
              // ── Filter groups ─────────────────────────────────────────
              const Divider(height: 24),
              ...groups.expand((group) => [
                    SheetSectionLabel(group.label.toUpperCase()),
                    ...group.filters.map((f) => CheckboxListTile(
                          title: Text(s.filterLabel(f)),
                          value: _filters.activeFilters.contains(f),
                          onChanged: (checked) {
                            final updated = checked == true
                                ? {..._filters.activeFilters, f}
                                : ({..._filters.activeFilters}
                                  ..remove(f));
                            _update(_filters.copyWith(
                              activeFilters: updated,
                            ));
                          },
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
  }
}

String _monthLabel(int month) =>
    DateFormat('MMM').format(DateTime(2000, month));

// ── Compact sort chip
// ──────────────────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: 16) : null,
      selected: isActive,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}
