import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../heat_map/services/heat_map_service.dart';
import '../models/sale.dart';
import '../models/sale_filter.dart';
import '../repositories/sale_repository.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

// Chips shown permanently in the filter row — covers daily workflow actions.
const _kPrimaryFilters = [
  SaleFilter.all,
  SaleFilter.unpaid,
  SaleFilter.pendingShipment,
  SaleFilter.overdue,
  SaleFilter.assemblyNotReady,
];

// Accessed via the filter icon in the AppBar — reference/info filters.
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

extension _SortOrderLabel on _SortOrder {
  String get label => switch (this) {
        _SortOrder.newestFirst => 'Newest first',
        _SortOrder.oldestFirst => 'Oldest first',
        _SortOrder.priceHigh => 'Price: high to low',
        _SortOrder.priceLow => 'Price: low to high',
      };
}

class _SalesListScreenState extends State<SalesListScreen> {
  final _repository = SaleRepository();
  late SaleFilter _filter;
  _ViewMode _viewMode = _ViewMode.timeline;
  _SortOrder _sortOrder = _SortOrder.newestFirst;

  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
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

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(
                  hintText: 'Search buyer or item...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            )
          : AppBar(
              title: const Text('Sales'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _isSearching = true),
                ),
                // Filter & sort sheet — badge when secondary filter or non-default sort active.
                Badge(
                  isLabelVisible: _kSecondaryFilters.contains(_filter) ||
                      _sortOrder != _SortOrder.newestFirst,
                  child: IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: 'Filter & sort',
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
                    _viewMenuItem(_ViewMode.list, Icons.list, 'List'),
                    _viewMenuItem(
                        _ViewMode.timeline, Icons.calendar_view_week, 'Timeline'),
                    _viewMenuItem(_ViewMode.map, Icons.map, 'Map'),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
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
                        label: Text(f.label),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    )),
                // When a secondary filter is active, surface it inline so the
                // user can see and clear it without opening the filter sheet.
                if (_kSecondaryFilters.contains(_filter))
                  FilterChip(
                    label: Text(_filter.label),
                    selected: true,
                    showCheckmark: false,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _filter = SaleFilter.all),
                    onSelected: (_) => setState(() => _filter = SaleFilter.all),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Sale>>(
              stream: _repository.watchSales(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var sales = _applyFilter(snapshot.data ?? []);
                sales = _applySearch(sales);
                sales = _applySort(sales);
                if (_viewMode != _ViewMode.map && sales.isEmpty) {
                  return const Center(child: Text('No sales found.'));
                }
                return switch (_viewMode) {
                  _ViewMode.list => _ListView(sales: sales),
                  _ViewMode.timeline => _TimelineView(sales: sales),
                  _ViewMode.map => _MapView(sales: sales),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet() {
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
                  child: Text('More filters',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                ..._kSecondaryFilters.map((f) => ListTile(
                      title: Text(f.label),
                      selected: _filter == f,
                      leading: _filter == f
                          ? const Icon(Icons.check)
                          : const SizedBox(width: 24),
                      onTap: () {
                        setState(() => _filter = f);
                        Navigator.pop(sheetContext);
                      },
                    )),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text('Sort by',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                ..._SortOrder.values.map((order) => ListTile(
                      title: Text(order.label),
                      selected: _sortOrder == order,
                      leading: _sortOrder == order
                          ? const Icon(Icons.check)
                          : const SizedBox(width: 24),
                      onTap: () {
                        setState(() => _sortOrder = order);
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
  String _status = 'Locating postal codes...';

  @override
  void initState() {
    super.initState();
    _load(widget.sales);
  }

  @override
  void didUpdateWidget(_MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCodes = HeatMapService.postalCounts(oldWidget.sales).keys.toSet();
    final newCodes = HeatMapService.postalCounts(widget.sales).keys.toSet();
    if (!oldCodes.containsAll(newCodes) || !newCodes.containsAll(oldCodes)) {
      _load(widget.sales);
    }
  }

  Future<void> _load(List<Sale> sales) async {
    setState(() {
      _loading = true;
      _status = 'Locating postal codes...';
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

  double _markerSize(int count) => (32 + (count - 1) * 8).clamp(32, 80).toDouble();

  @override
  Widget build(BuildContext context) {
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
                          onTap: () => ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text(
                                '${p.postalCode} — ${p.count} sale${p.count == 1 ? '' : 's'}'),
                            duration: const Duration(seconds: 2),
                          )),
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
                    const Text('No shipped sales with postal codes.'),
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
                      '${_points.length} postal code${_points.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '${_points.fold(0, (s, p) => s + p.count)} shipped sale${_points.fold(0, (s, p) => s + p.count) == 1 ? '' : 's'}',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sales.length,
      itemBuilder: (context, index) => _SaleCard(sale: sales[index]),
    );
  }
}

class _TimelineView extends StatelessWidget {
  final List<Sale> sales;

  const _TimelineView({required this.sales});

  Map<String, List<Sale>> _groupByWeek(List<Sale> sales) {
    final now = DateTime.now();
    final Map<String, List<Sale>> groups = {};
    // Preserve order: Overdue → This week → Next week → Later → past months
    const order = ['Overdue', 'This week', 'Next week', 'Later'];

    for (final sale in sales) {
      final label = _weekLabel(sale, now);
      groups.putIfAbsent(label, () => []).add(sale);
    }

    final sorted = <String, List<Sale>>{};
    for (final key in order) {
      if (groups.containsKey(key)) sorted[key] = groups[key]!;
    }
    for (final key in groups.keys) {
      if (!order.contains(key)) sorted[key] = groups[key]!;
    }
    return sorted;
  }

  String _weekLabel(Sale sale, DateTime now) {
    final relevantDate = sale.scheduledDate ?? sale.createdAt;
    final startOfThisWeek =
        DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
    final startOfNextWeek =
        startOfThisWeek.add(const Duration(days: 7));
    final endOfNextWeek =
        startOfNextWeek.add(const Duration(days: 7));

    // Overdue: has a scheduled date in the past and not yet delivered
    if (sale.scheduledDate != null &&
        sale.scheduledDate!.isBefore(startOfThisWeek) &&
        sale.shipment.status != ShipmentStatus.delivered) {
      return 'Overdue';
    }
    if (relevantDate.isAfter(
        startOfThisWeek.subtract(const Duration(seconds: 1))) &&
        relevantDate.isBefore(startOfNextWeek)) {
      return 'This week';
    }
    if (relevantDate.isAfter(
        startOfNextWeek.subtract(const Duration(seconds: 1))) &&
        relevantDate.isBefore(endOfNextWeek)) {
      return 'Next week';
    }
    if (relevantDate.isAfter(endOfNextWeek)) {
      return 'Later';
    }
    return DateFormat('MMMM yyyy').format(relevantDate);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByWeek(sales);
    final keys = groups.keys.toList();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final label = keys[index];
        final groupSales = groups[label]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...groupSales.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _SaleCard(sale: s),
                )),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}

// Returns blocker reasons for the ⚠️ badge. Empty list = no badge.
typedef _UrgencyReason = ({String label, IconData icon, Color color});

List<_UrgencyReason> _urgencyReasons(Sale sale) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfThisWeek = today.subtract(Duration(days: now.weekday - 1));
  final startOfNextWeek = startOfThisWeek.add(const Duration(days: 7));

  if (sale.scheduledDate == null) return [];
  if (sale.shipment.status == ShipmentStatus.delivered) return [];

  final isOverdue = sale.scheduledDate!.isBefore(startOfThisWeek);
  final isThisWeek = !isOverdue && sale.scheduledDate!.isBefore(startOfNextWeek);
  if (!isOverdue && !isThisWeek) return [];

  final reasons = <_UrgencyReason>[];
  if (sale.assemblyStatus == AssemblyStatus.waitingForMaterials) {
    reasons.add((
      label: 'Waiting for materials',
      icon: Icons.shopping_bag_outlined,
      color: Colors.amber[700]!,
    ));
  } else if (sale.assemblyStatus != AssemblyStatus.ready) {
    reasons.add((
      label: 'Assembly not ready',
      icon: Icons.construction,
      color: Colors.amber[700]!,
    ));
  }
  if (sale.payment.status == PaymentStatus.unpaid) {
    reasons.add((
      label: 'Payment pending',
      icon: Icons.credit_card_off,
      color: Colors.orange,
    ));
  }
  if (isOverdue && sale.shipment.status == ShipmentStatus.pending) {
    reasons.add((
      label: 'Not yet shipped',
      icon: Icons.schedule,
      color: Colors.red,
    ));
  }
  return reasons;
}

// Returns days until scheduled date (negative = overdue). Null if no date.
int? _daysUntilScheduled(Sale sale) {
  if (sale.scheduledDate == null) return null;
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final scheduled = DateTime(
    sale.scheduledDate!.year,
    sale.scheduledDate!.month,
    sale.scheduledDate!.day,
  );
  return scheduled.difference(todayDate).inDays;
}

class _SaleCard extends StatelessWidget {
  final Sale sale;

  const _SaleCard({required this.sale});

  bool _isOverdue() {
    final days = _daysUntilScheduled(sale);
    return days != null && days < 0;
  }

  Color? _accentColor(BuildContext context) {
    if (_urgencyReasons(sale).isEmpty) return null;
    return _isOverdue() ? Theme.of(context).colorScheme.error : Colors.amber[700]!;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    final accentColor = _accentColor(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SaleDetailScreen(saleId: sale.id)),
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
                        _AttentionBadges(sale: sale),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          dateFormat.format(sale.createdAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const Spacer(),
                        if (sale.scheduledDate != null)
                          _ScheduledDateLabel(sale: sale),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showPathLegend(context),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          _SaleProgressPath(sale: sale),
                        ],
                      ),
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

  const _AttentionBadges({required this.sale});

  @override
  Widget build(BuildContext context) {
    final nifPaid = sale.requiresNif && sale.payment.status == PaymentStatus.paid;
    final reasons = _urgencyReasons(sale);

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
                color: sale.atSubmissionDone ? Colors.green : Colors.purple,
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
    final days = _daysUntilScheduled(sale)!;
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

    final label = isDelivered
        ? '📅 ${DateFormat('dd MMM').format(sale.scheduledDate!)}'
        : days < 0
            ? '📅 ${DateFormat('dd MMM').format(sale.scheduledDate!)} (${days.abs()}d overdue)'
            : days == 0
                ? '📅 Today'
                : days == 1
                    ? '📅 Tomorrow'
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
                  color: atSubmissionDone ? Colors.green : Colors.purple),
              const SizedBox(width: 12),
              Text(
                atSubmissionDone
                    ? 'Filed with AT'
                    : 'NIF receipt required',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            atSubmissionDone
                ? 'This receipt has been filed with AT.'
                : 'Payment received — file this sale\'s receipt with AT. '
                    'The buyer\'s NIF is available on their profile.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

void _showUrgencyDetail(
    BuildContext context, List<_UrgencyReason> reasons) {
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Action needed',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...reasons.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(r.icon, size: 20, color: r.color),
                  const SizedBox(width: 12),
                  Text(r.label,
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

void _showPathLegend(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sale progress',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _LegendRow(Icons.build_outlined, Colors.grey, 'Assembly: not started'),
          _LegendRow(Icons.shopping_bag_outlined, Colors.amber[700]!,
              'Assembly: waiting for materials'),
          _LegendRow(Icons.build_outlined, Colors.amber[700]!,
              'Assembly: in progress'),
          _LegendRow(Icons.build, Colors.green, 'Assembly: ready'),
          const Divider(height: 20),
          _LegendRow(Icons.payments_outlined, Colors.grey, 'Payment: unpaid'),
          _LegendRow(Icons.payments, Colors.green, 'Payment: paid'),
          const Divider(height: 20),
          _LegendRow(
              Icons.local_shipping_outlined, Colors.grey, 'Shipment: pending'),
          _LegendRow(Icons.local_shipping, Colors.blue, 'Shipment: shipped'),
          _LegendRow(
              Icons.local_shipping, Colors.green, 'Shipment: delivered'),
          _LegendRow(Icons.store, Colors.green, 'Pickup (no shipment needed)'),
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
      AssemblyStatus.inProgress => (Icons.build_outlined, Colors.amber[700]!),
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
