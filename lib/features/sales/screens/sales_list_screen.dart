import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/store/buyers_store.dart';
import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/core/store/store_state.dart';
import 'package:latitude_tracker/core/widgets/store_error_widget.dart';
import 'package:latitude_tracker/features/heat_map/screens/geographic_sales_screen.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/models/sale_filter.dart';
import 'package:latitude_tracker/features/sales/models/sales_list_filters.dart';
import 'package:latitude_tracker/features/sales/repositories/sale_repository.dart';
import 'package:latitude_tracker/features/sales/screens/new_sale_screen.dart';
import 'package:latitude_tracker/features/sales/screens/sale_detail_screen.dart';
import 'package:latitude_tracker/features/sales/screens/sale_timeline_view.dart';
import 'package:latitude_tracker/features/sales/screens/sales_filter_sheet.dart';
import 'package:latitude_tracker/features/sales/services/sales_list_presenter.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({
    super.key,
    this.initialFilters = const <SaleFilter>{},
    this.postalCodePrefix,
    this.appBarTitle,
  }) : assert(
          postalCodePrefix == null || appBarTitle != null,
          'appBarTitle is required when postalCodePrefix is set',
        );
  final Set<SaleFilter> initialFilters;
  /// When set, filters the list to sales with this CP4 postal prefix and
  /// overrides the active-only default so delivered sales are also shown.
  final String? postalCodePrefix;
  final String? appBarTitle;

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  late SalesListFilters _filters;
  late SalesListResult _result;
  final _repository = SaleRepository();

  final _searchController = TextEditingController();
  bool _searchExpanded = false;

  Sale? _selectedSale;
  final _rightPanelKey = GlobalKey<NavigatorState>();
  final _editModeSignal = ValueNotifier<int>(0);

  bool get _loading => SalesStore.current == null;

  // Counts active filter/sort constraints for the tune-icon badge.
  int get _activeFilterCount =>
      _filters.activeFilters.length +
      _filters.categoryFilters.length +
      (_filters.selectedYear != null ? 1 : 0) +
      (_filters.buyerFilter != null ? 1 : 0) +
      (_filters.sortOrder != SortOrder.newestFirst ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _filters = SalesListFilters(
      activeFilters: Set<SaleFilter>.from(widget.initialFilters),
      postalCodePrefix: widget.postalCodePrefix,
    );
    SalesStore.state.addListener(_onStoreChanged);
    BuyersStore.state.addListener(_onStoreChanged);
    _rebuildCache();
  }

  void _onStoreChanged() {
    _rebuildCache();
    setState(() {});
  }

  void _rebuildCache() {
    _result = SalesListPresenter.compute(
      SalesStore.currentOrEmpty,
      BuyersStore.currentOrEmpty,
      _filters,
    );
  }

  Future<void> _markSalePaid(Sale sale, PaymentMethod method) async {
    try {
      await _repository.patchSale(sale.id, {
        'payment.status': PaymentStatus.paid.name,
        'payment.method': method.name,
      });
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.errorSavingSaleMsg(e))),
      );
    }
  }

  Future<void> _markSaleShipped(
    Sale sale, {
    required DateTime shippedAt,
    String? trackingCode,
  }) async {
    try {
      await _repository.patchSale(sale.id, {
        'shipment.status': ShipmentStatus.shipped.name,
        // null explicitly clears a previously-set tracking code in Firestore.
        'shipment.trackingCode': trackingCode,
        'shipment.shippedAt': Timestamp.fromDate(shippedAt),
      });
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.errorSavingSaleMsg(e))),
      );
    }
  }

  @override
  void dispose() {
    SalesStore.state.removeListener(_onStoreChanged);
    BuyersStore.state.removeListener(_onStoreChanged);
    _searchController.dispose();
    _editModeSignal.dispose();
    super.dispose();
  }

  bool _isTablet() => MediaQuery.sizeOf(context).width >= 600;

  void _selectSale(Sale sale) {
    if (!_isTablet()) {
      unawaited(Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SaleDetailScreen(saleId: sale.id),
        ),
      ));
      return;
    }
    if (_selectedSale?.id == sale.id) return;
    _editModeSignal.value = 0;
    setState(() => _selectedSale = sale);
    final nav = _rightPanelKey.currentState;
    if (nav != null) {
      nav.popUntil((r) => r.isFirst);
      unawaited(nav.push(MaterialPageRoute<void>(
        builder: (_) => SaleDetailScreen(
          saleId: sale.id,
          editModeSignal: _editModeSignal,
        ),
      )));
    }
  }

  void _openNewSale() {
    if (!_isTablet()) {
      unawaited(Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const NewSaleScreen()),
      ));
      return;
    }
    setState(() => _selectedSale = null);
    final nav = _rightPanelKey.currentState;
    if (nav != null) {
      nav.popUntil((r) => r.isFirst);
      unawaited(nav.push(MaterialPageRoute<void>(
        builder: (_) => const NewSaleScreen(),
      )));
    }
  }

  void _showOptionsSheet() {
    unawaited(showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SalesFilterSheet(
        filters: _filters,
        availableYears: _result.availableYears,
        availableCategories: _result.availableCategories,
        onFiltersChanged: (updated) {
          if (updated.searchQuery.isEmpty &&
              _filters.searchQuery.isNotEmpty) {
            _searchController.clear();
            _searchExpanded = false;
          }
          _filters = updated;
          _rebuildCache();
          setState(() {});
        },
      ),
    ));
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
              if (_searchExpanded)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: s.searchSales,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _filters = _filters.copyWith(searchQuery: '');
                          _rebuildCache();
                          setState(() => _searchExpanded = false);
                        },
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      _filters = _filters.copyWith(searchQuery: v);
                      _rebuildCache();
                      setState(() {});
                    },
                  ),
                )
              else ...[
                FilterChip(
                  avatar: const Icon(Icons.search, size: 18),
                  label: Text(s.searchSales),
                  onSelected: (_) =>
                      setState(() => _searchExpanded = true),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
              ],
              Badge(
                label: filterCount > 0 ? Text('$filterCount') : null,
                isLabelVisible: filterCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: s.moreFilters,
                  onPressed: _showOptionsSheet,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined),
                tooltip: s.geographicSalesTitle,
                onPressed: () => unawaited(Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const GeographicSalesScreen()),
                )),
              ),
            ],
          ),
        ),
        Expanded(
          child: SalesStore.state.value is StoreError
              ? StoreErrorWidget(
                  message: s.errorLoadingSales,
                  onRetry: SalesStore.ensureSubscribed,
                )
              : _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _result.filteredSales.isEmpty
                      ? Center(child: Text(s.noSalesFound))
                      : TimelineView(
                          groups: _result.groupedSales,
                          buyerNifById: _result.buyerNifById,
                          selectedSaleId:
                              isTablet ? _selectedSale?.id : null,
                          onSaleTap: _selectSale,
                          onMarkPaid: _markSalePaid,
                          onMarkShipped: _markSaleShipped,
                        ),
        ),
      ],
    );

    final fab = isTablet && _selectedSale != null
        ? FloatingActionButton(
            heroTag: null,
            tooltip: context.s.editSale,
            onPressed: () => _editModeSignal.value++,
            child: const Icon(Icons.edit),
          )
        : FloatingActionButton(
            heroTag: null,
            onPressed: _openNewSale,
            child: const Icon(Icons.add),
          );

    final appBar = widget.appBarTitle != null
        ? AppBar(title: Text(widget.appBarTitle!))
        : null;

    if (!isTablet) {
      return Scaffold(
        appBar: appBar,
        floatingActionButton: fab,
        body: SafeArea(bottom: false, child: listPanel),
      );
    }

    return Scaffold(
      appBar: appBar,
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
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => const _RightPanelPlaceholder(),
                ),
              ),
            ),
          ],
        ),
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
