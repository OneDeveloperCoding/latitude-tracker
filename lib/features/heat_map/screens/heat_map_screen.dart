import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/sales_store.dart';
import '../../sales/models/sale.dart';
import '../services/heat_map_service.dart';

class HeatMapScreen extends StatefulWidget {
  const HeatMapScreen({super.key});

  @override
  State<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends State<HeatMapScreen> {
  List<HeatMapPoint> _points = [];
  bool _loading = true;
  String _status = '';

  // Available years derived from sales with postal codes.
  List<int> _years = [];
  // null = all years
  int? _selectedYear;
  bool _includeHandDelivery = true;

  // Created once so the tile cache singleton isn't re-instantiated on rebuild.
  late final NetworkTileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileProvider = NetworkTileProvider(
      cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: 50 * 1024 * 1024, // 50 MB — plenty for Portugal
      ),
    );
    SalesStore.state.addListener(_onStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rebuild();
    });
  }

  @override
  void dispose() {
    SalesStore.state.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) _rebuild();
  }

  void _rebuild() {
    final all = _shippedSalesWithPostalCode(SalesStore.current ?? []);
    final years = all
        .map((s) => s.createdAt.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    // If the selected year no longer exists in the data, reset to all.
    final year =
        (_selectedYear != null && years.contains(_selectedYear))
            ? _selectedYear
            : null;

    setState(() {
      _years = years;
      _selectedYear = year;
    });

    _load(all, year);
  }

  Future<void> _load(List<Sale> sales, int? year) async {
    final filtered =
        year == null ? sales : sales.where((s) => s.createdAt.year == year).toList();

    setState(() {
      _loading = true;
      _status = context.s.locatingPostalCodes;
    });

    final points = await HeatMapService.buildPoints(
      filtered,
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

  void _selectYear(int? year) {
    if (year == _selectedYear) return;
    setState(() => _selectedYear = year);
    _load(
      _shippedSalesWithPostalCode(SalesStore.current ?? []),
      year,
    );
  }

  List<Sale> _shippedSalesWithPostalCode(List<Sale> sales) => sales
      .where((s) =>
          (s.shipment.type == DeliveryType.shipping ||
              (_includeHandDelivery &&
                  s.shipment.type == DeliveryType.handDelivery)) &&
          s.shipment.postalCode != null &&
          s.shipment.postalCode!.isNotEmpty)
      .toList();

  double _markerSize(int count) =>
      (32 + (count - 1) * 8).clamp(32, 80).toDouble();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.salesHeatMapTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_walk),
            tooltip: s.handDelivery,
            isSelected: _includeHandDelivery,
            onPressed: () {
              setState(() => _includeHandDelivery = !_includeHandDelivery);
              _load(
                _shippedSalesWithPostalCode(SalesStore.current ?? []),
                _selectedYear,
              );
            },
          ),
        ],
        bottom: _years.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _YearFilterBar(
                  years: _years,
                  selected: _selectedYear,
                  allLabel: s.allYears,
                  onSelected: _selectYear,
                ),
              ),
      ),
      body: Stack(
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
                tileProvider: _tileProvider,
                keepBuffer: 3,
                panBuffer: 2,
                tileDisplay: const TileDisplay.instantaneous(),
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
                                  '${p.locality} (${p.postalCode}) — ${s.nSales(p.count)}',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            ),
                            child: _MapMarker(
                              count: p.count,
                              size: _markerSize(p.count),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          if (_loading) _LoadingOverlay(status: _status),
          if (!_loading && _points.isEmpty) _EmptyOverlay(s: s),
          if (!_loading && _points.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              child: _Legend(points: _points, s: s),
            ),
        ],
      ),
    );
  }
}

class _YearFilterBar extends StatelessWidget {
  final List<int> years;
  final int? selected;
  final String allLabel;
  final void Function(int?) onSelected;

  const _YearFilterBar({
    required this.years,
    required this.selected,
    required this.allLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _chip(context, label: allLabel, value: null),
          ...years.map((y) => _chip(context, label: '$y', value: y)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, {required String label, required int? value}) {
    final isSelected = value == selected;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(isSelected ? null : value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final int count;
  final double size;

  const _MapMarker({required this.count, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(160),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final String status;

  const _LoadingOverlay({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(status, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOverlay extends StatelessWidget {
  final AppStrings s;

  const _EmptyOverlay({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(s.noShippedSalesWithPostalCode),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<HeatMapPoint> points;
  final AppStrings s;

  const _Legend({required this.points, required this.s});

  @override
  Widget build(BuildContext context) {
    final total = points.fold(0, (sum, p) => sum + p.count);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.nPostalCodes(points.length),
                style: Theme.of(context).textTheme.labelSmall),
            Text(s.nSales(total),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
