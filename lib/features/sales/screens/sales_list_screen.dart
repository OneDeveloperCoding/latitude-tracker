import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../heat_map/services/geocoding_service.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

enum SaleFilter {
  all,
  unpaid,
  nifRequired,
  scheduled,
  pendingShipment,
  shipped,
  pickup,
  assemblyNotReady,
  overdue,
}

extension SaleFilterLabel on SaleFilter {
  String get label => switch (this) {
        SaleFilter.all => 'All',
        SaleFilter.unpaid => 'Unpaid',
        SaleFilter.nifRequired => 'NIF required',
        SaleFilter.scheduled => 'Scheduled',
        SaleFilter.pendingShipment => 'Pending shipment',
        SaleFilter.shipped => 'Shipped',
        SaleFilter.pickup => 'Pickup',
        SaleFilter.assemblyNotReady => 'Assembly not ready',
        SaleFilter.overdue => 'Overdue',
      };
}

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

class _SalesListScreenState extends State<SalesListScreen> {
  final _repository = SaleRepository();
  late SaleFilter _filter;
  _ViewMode _viewMode = _ViewMode.list;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  List<Sale> _applyFilter(List<Sale> sales) => switch (_filter) {
        SaleFilter.all => sales,
        SaleFilter.unpaid =>
          sales.where((s) => s.payment.status == PaymentStatus.unpaid).toList(),
        SaleFilter.nifRequired =>
          sales.where((s) => s.requiresNif).toList(),
        SaleFilter.scheduled =>
          sales.where((s) => s.scheduledDate != null).toList(),
        SaleFilter.pendingShipment => sales
            .where((s) =>
                s.shipment.type == DeliveryType.shipping &&
                s.shipment.status == ShipmentStatus.pending)
            .toList(),
        SaleFilter.shipped => sales
            .where((s) => s.shipment.status == ShipmentStatus.shipped)
            .toList(),
        SaleFilter.pickup => sales
            .where((s) => s.shipment.type == DeliveryType.pickup)
            .toList(),
        SaleFilter.assemblyNotReady => sales
            .where((s) => s.assemblyStatus != AssemblyStatus.ready)
            .toList(),
        SaleFilter.overdue => sales
            .where((s) =>
                s.scheduledDate != null &&
                s.scheduledDate!.isBefore(DateTime.now()) &&
                s.shipment.status != ShipmentStatus.delivered)
            .toList(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          PopupMenuButton<_ViewMode>(
            icon: Icon(switch (_viewMode) {
              _ViewMode.list => Icons.list,
              _ViewMode.timeline => Icons.calendar_view_week,
              _ViewMode.map => Icons.map,
            }),
            onSelected: (mode) => setState(() => _viewMode = mode),
            itemBuilder: (_) => [
              _viewMenuItem(_ViewMode.list, Icons.list, 'List'),
              _viewMenuItem(_ViewMode.timeline, Icons.calendar_view_week, 'Timeline'),
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
              children: SaleFilter.values
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f.label),
                          selected: _filter == f,
                          onSelected: (_) =>
                              setState(() => _filter = f),
                        ),
                      ))
                  .toList(),
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
                final sales = _applyFilter(snapshot.data ?? []);
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

class _PostalCodePoint {
  final String postalCode;
  final LatLng position;
  final int count;

  const _PostalCodePoint({
    required this.postalCode,
    required this.position,
    required this.count,
  });
}

class _MapView extends StatefulWidget {
  final List<Sale> sales;

  const _MapView({required this.sales});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  List<_PostalCodePoint> _points = [];
  bool _loading = true;
  String _status = 'Locating postal codes...';

  @override
  void initState() {
    super.initState();
    _geocode(widget.sales);
  }

  @override
  void didUpdateWidget(_MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCodes = _postalCodes(oldWidget.sales);
    final newCodes = _postalCodes(widget.sales);
    if (!oldCodes.containsAll(newCodes) || !newCodes.containsAll(oldCodes)) {
      _geocode(widget.sales);
    }
  }

  Map<String, int> _extractPostalCounts(List<Sale> sales) {
    final counts = <String, int>{};
    for (final sale in sales) {
      final code = sale.shipment.postalCode;
      if (sale.shipment.type == DeliveryType.shipping &&
          code != null &&
          code.isNotEmpty) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
    }
    return counts;
  }

  Set<String> _postalCodes(List<Sale> sales) =>
      _extractPostalCounts(sales).keys.toSet();

  Future<void> _geocode(List<Sale> sales) async {
    setState(() {
      _loading = true;
      _status = 'Locating postal codes...';
    });

    final counts = _extractPostalCounts(sales);
    final points = <_PostalCodePoint>[];
    var done = 0;

    for (final entry in counts.entries) {
      if (!mounted) return;
      setState(() =>
          _status = 'Locating ${entry.key} ($done/${counts.length})...');

      final latLng = await GeocodingService.geocode(entry.key);
      if (latLng != null) {
        points.add(_PostalCodePoint(
          postalCode: entry.key,
          position: latLng,
          count: entry.value,
        ));
      }

      done++;
      // Nominatim requires max 1 request/second
      await Future.delayed(const Duration(seconds: 1));
    }

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
      itemCount: sales.length,
      itemBuilder: (context, index) => _SaleTile(sale: sales[index]),
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
            ...groupSales.map((s) => _SaleTile(sale: s)),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;

  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');
    final isPickup = sale.shipment.type == DeliveryType.pickup;

    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(sale.buyerName, overflow: TextOverflow.ellipsis),
          ),
          if (sale.requiresNif) ...[
            const SizedBox(width: 4),
            _MiniChip(label: 'NIF', color: Colors.purple),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sale.itemDescription,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sale.scheduledDate != null)
            Text(
              '📅 ${DateFormat('dd MMM').format(sale.scheduledDate!)}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
        ],
      ),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '€${sale.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            dateFormat.format(sale.createdAt),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _MiniChip(
            label:
                sale.payment.status == PaymentStatus.paid ? 'Paid' : 'Unpaid',
            color: sale.payment.status == PaymentStatus.paid
                ? Colors.green
                : Colors.orange,
          ),
          const SizedBox(height: 4),
          _MiniChip(
            label: isPickup ? '📦 Pickup' : sale.shipment.status.label,
            color: isPickup
                ? Colors.teal
                : sale.shipment.status == ShipmentStatus.delivered
                    ? Colors.green
                    : sale.shipment.status == ShipmentStatus.shipped
                        ? Colors.blue
                        : Colors.grey,
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SaleDetailScreen(saleId: sale.id),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}
