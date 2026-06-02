import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/sales_store.dart';
import '../../heat_map/services/heat_map_service.dart';
import '../models/sale.dart';
import '../models/sale_filter.dart';
import '../services/sale_grouper.dart';
import '../services/sale_urgency.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

const _kPrimaryFilters = [
  SaleFilter.all,
  SaleFilter.unpaid,
  SaleFilter.pendingShipment,
  SaleFilter.overdue,
  SaleFilter.assemblyNotReady,
];

const _kSecondaryFilters = [
  SaleFilter.shipped,
  SaleFilter.nifRequired,
  SaleFilter.scheduled,
  SaleFilter.pickup,
];

class SalesListScreen extends StatefulWidget {
  final SaleFilter initialFilter;

  const SalesListScreen({
    super.key,
    this.initialFilter = SaleFilter.all,
  });

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

enum _ViewMode { list, timeline, map }

enum _SortOrder { newestFirst, oldestFirst, priceHigh, priceLow }

class _SalesListScreenState extends State<SalesListScreen> {
  late SaleFilter _filter;
  _ViewMode _viewMode = _ViewMode.timeline;
  _SortOrder _sortOrder = _SortOrder.newestFirst;

  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Cached once per store/filter/sort/search change — not on every build().
  List<Sale> _filteredSales = [];
  Map<String, List<Sale>> _groupedSales = {};

  bool get _loading => SalesStore.current == null;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
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
    _groupedSales = SaleGrouper.byWeek(sales);
  }

  @override
  void dispose() {
    SalesStore.state.removeListener(_onStoreChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _stopSearch() {
    _isSearching = false;
    _searchQuery = '';
    _searchController.clear();
    _rebuildCache();
    setState(() {});
  }

  List<Sale> _applyFilter(List<Sale> sales) =>
      _filter == SaleFilter.all ? sales : sales.where(_filter.test).toList();

  List<Sale> _applySearch(List<Sale> sales) {
    if (_searchQuery.isEmpty) return sales;
    final q = _searchQuery.toLowerCase();
    return sales
        .where((s) =>
            s.buyerName.toLowerCase().contains(q) ||
            s.itemDescription.toLowerCase().contains(q))
        .toList();
  }

  List<Sale> _applySort(List<Sale> sales) {
    if (_sortOrder == _SortOrder.newestFirst) return sales;
    final sorted = List<Sale>.from(sales);
    switch (_sortOrder) {
      case _SortOrder.oldestFirst:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortOrder.priceHigh:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case _SortOrder.priceLow:
        sorted.sort((a, b) => a.price.compareTo(b.price));
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

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: _isSearching
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _stopSearch,
              ),
              title: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: s.searchSales,
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                _searchQuery = v;
                _rebuildCache();
                setState(() {});
              },
              ),
            )
          : AppBar(
              title: Text(s.navSales),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _isSearching = true),
                ),
                Badge(
                  isLabelVisible: _kSecondaryFilters.contains(_filter) ||
                      _sortOrder != _SortOrder.newestFirst,
                  child: IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: s.filterSort,
                    onPressed: _showOptionsSheet,
                  ),
                ),
                PopupMenuButton<_ViewMode>(
                  icon: Icon(switch (_viewMode) {
                    _ViewMode.list => Icons.list,
                    _ViewMode.timeline => Icons.calendar_view_week,
                    _ViewMode.map => Icons.map,
                  }),
                  onSelected: (mode) => setState(() => _viewMode = mode),
                  itemBuilder: (_) => [
                    _viewMenuItem(_ViewMode.list, Icons.list, s.viewList),
                    _viewMenuItem(_ViewMode.timeline,
                        Icons.calendar_view_week, s.viewTimeline),
                    _viewMenuItem(_ViewMode.map, Icons.map, s.viewMap),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: s.legendTitle,
                  onPressed: () => _showPathLegend(context, s),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewSaleScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ..._kPrimaryFilters.map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s.filterLabel(f)),
                        selected: _filter == f,
                        onSelected: (_) {
                          _filter = f;
                          _rebuildCache();
                          setState(() {});
                        },
                      ),
                    )),
                if (_kSecondaryFilters.contains(_filter))
                  FilterChip(
                    label: Text(s.filterLabel(_filter)),
                    selected: true,
                    showCheckmark: false,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      _filter = SaleFilter.all;
                      _rebuildCache();
                      setState(() {});
                    },
                    onSelected: (_) {
                      _filter = SaleFilter.all;
                      _rebuildCache();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _viewMode != _ViewMode.map && _filteredSales.isEmpty
                    ? Center(child: Text(s.noSalesFound))
                    : switch (_viewMode) {
                        _ViewMode.list => _ListView(sales: _filteredSales),
                        _ViewMode.timeline =>
                          _TimelineView(groups: _groupedSales),
                        _ViewMode.map => _MapView(sales: _filteredSales),
                      },
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet() {
    final s = context.s;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(s.moreFilters,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                ..._kSecondaryFilters.map((f) => ListTile(
                      title: Text(s.filterLabel(f)),
                      selected: _filter == f,
                      leading: _filter == f
                          ? const Icon(Icons.check)
                          : const SizedBox(width: 24),
                      onTap: () {
                        _filter = f;
                        _rebuildCache();
                        setState(() {});
                        Navigator.pop(sheetContext);
                      },
                    )),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(s.sortBy,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                ..._SortOrder.values.map((order) => ListTile(
                      title: Text(_sortOrderLabel(order)),
                      selected: _sortOrder == order,
                      leading: _sortOrder == order
                          ? const Icon(Icons.check)
                          : const SizedBox(width: 24),
                      onTap: () {
                        _sortOrder = order;
                        _rebuildCache();
                        setState(() {});
                        setSheetState(() {});
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_ViewMode> _viewMenuItem(
      _ViewMode mode, IconData icon, String label) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
          if (_viewMode == mode) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16),
          ],
        ],
      ),
    );
  }
}

// ── Map view ──────────────────────────────────────────────────────────────────

class _MapView extends StatefulWidget {
  final List<Sale> sales;

  const _MapView({required this.sales});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  List<HeatMapPoint> _points = [];
  bool _loading = true;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _status = context.s.locatingPostalCodes;
    _load(widget.sales);
  }

  @override
  void didUpdateWidget(_MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCodes =
        HeatMapService.postalCounts(oldWidget.sales).keys.toSet();
    final newCodes = HeatMapService.postalCounts(widget.sales).keys.toSet();
    if (!oldCodes.containsAll(newCodes) ||
        !newCodes.containsAll(oldCodes)) {
      _load(widget.sales);
    }
  }

  Future<void> _load(List<Sale> sales) async {
    final s = context.s;
    setState(() {
      _loading = true;
      _status = s.locatingPostalCodes;
    });

    final points = await HeatMapService.buildPoints(
      sales,
      onProgress: (status, done, total) {
        if (mounted) setState(() => _status = '$status ($done/$total)...');
      },
    );

    if (mounted) {
      setState(() {
        _points = points;
        _loading = false;
      });
    }
  }

  double _markerSize(int count) =>
      (32 + (count - 1) * 8).clamp(32, 80).toDouble();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(39.5, -8.0),
            initialZoom: 6.5,
            minZoom: 5,
            maxZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.latitude.tracker',
            ),
            MarkerLayer(
              markers: _points
                  .map((p) => Marker(
                        point: p.position,
                        width: _markerSize(p.count),
                        height: _markerSize(p.count),
                        child: GestureDetector(
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${p.postalCode} — ${s.nSales(p.count)}'),
                              duration: const Duration(seconds: 2),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(160),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${p.count}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        if (_loading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_status, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!_loading && _points.isEmpty)
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(s.noShippedSalesWithPostalCode),
                  ],
                ),
              ),
            ),
          ),
        if (!_loading && _points.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.nPostalCodes(_points.length),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      s.nSales(_points.fold(0, (sum, p) => sum + p.count)),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── List view ─────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  final List<Sale> sales;

  const _ListView({required this.sales});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      itemCount: sales.length,
      itemBuilder: (context, index) => _SaleCard(sale: sales[index]),
    );
  }
}

class _TimelineView extends StatelessWidget {
  final Map<String, List<Sale>> groups;

  const _TimelineView({required this.groups});

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
                  child: _SaleCard(sale: sale),
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

  const _SaleCard({required this.sale});

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
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SaleDetailScreen(saleId: sale.id)),
        ),
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
                    '€${sale.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      sale.itemDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  _AttentionBadges(sale: sale, reasons: reasons),
                ],
              ),
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
    final nifPaid =
        sale.requiresNif && sale.payment.status == PaymentStatus.paid;

    if (!nifPaid && reasons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (nifPaid) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showNifDetail(context, sale.atSubmissionDone),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.receipt_long,
                size: 22,
                color:
                    sale.atSubmissionDone ? Colors.green : Colors.purple,
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

void _showNifDetail(BuildContext context, bool atSubmissionDone) {
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
              Icon(Icons.receipt_long,
                  color:
                      atSubmissionDone ? Colors.green : Colors.purple),
              const SizedBox(width: 12),
              Text(
                atSubmissionDone ? s.atFiledWithAt : s.nifSheetTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            atSubmissionDone ? s.atFiledWithAtBody : s.nifSheetBody,
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
        _line(sale.assemblyStatus == AssemblyStatus.ready),
        _paymentNode(),
        _line(sale.payment.status == PaymentStatus.paid),
        _shipmentNode(),
      ],
    );
  }

  Widget _assemblyNode() {
    final (icon, color) = switch (sale.assemblyStatus) {
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
