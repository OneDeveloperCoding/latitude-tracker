import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../sales/models/sale.dart';
import '../../sales/repositories/sale_repository.dart';
import '../services/geocoding_service.dart';

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

class HeatMapScreen extends StatefulWidget {
  const HeatMapScreen({super.key});

  @override
  State<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends State<HeatMapScreen> {
  List<_PostalCodePoint> _points = [];
  bool _loading = true;
  String _status = 'Loading sales...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _status = 'Loading sales...';
      _error = null;
    });

    try {
      final sales = await SaleRepository().watchSales().first;
      final postalCodes = _extractPostalCodes(sales);

      if (postalCodes.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final points = <_PostalCodePoint>[];
      var resolved = 0;

      for (final entry in postalCodes.entries) {
        if (!mounted) return;
        setState(() =>
            _status = 'Locating ${entry.key} ($resolved/${postalCodes.length})...');

        final latLng = await GeocodingService.geocode(entry.key);
        if (latLng != null) {
          points.add(_PostalCodePoint(
            postalCode: entry.key,
            position: latLng,
            count: entry.value,
          ));
        }

        resolved++;
        // Nominatim rate limit: 1 request/second
        await Future.delayed(const Duration(seconds: 1));
      }

      if (mounted) {
        setState(() {
          _points = points;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // Counts shipped sales by postal code (ignores pickups and sales without a code).
  Map<String, int> _extractPostalCodes(List<Sale> sales) {
    final counts = <String, int>{};
    for (final sale in sales) {
      final code = sale.shipment.postalCode;
      if (sale.shipment.type == DeliveryType.shipping && code != null && code.isNotEmpty) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
    }
    return counts;
  }

  double _markerSize(int count) {
    // 32px base, +8px per additional sale, capped at 80px
    return (32 + (count - 1) * 8).clamp(32, 80).toDouble();
  }

  void _showPointInfo(BuildContext context, _PostalCodePoint point) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${point.postalCode} — ${point.count} sale${point.count == 1 ? '' : 's'}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Heat Map'),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _load,
            ),
        ],
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
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.latitude.tracker',
              ),
              MarkerLayer(
                markers: _points
                    .map((p) => Marker(
                          point: p.position,
                          width: _markerSize(p.count),
                          height: _markerSize(p.count),
                          child: GestureDetector(
                            onTap: () => _showPointInfo(context, p),
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
          if (!_loading && _points.isEmpty && _error == null)
            const _EmptyOverlay(),
          if (_error != null) _ErrorOverlay(message: _error!, onRetry: _load),
          if (!_loading && _points.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              child: _Legend(points: _points),
            ),
        ],
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
  const _EmptyOverlay();

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
              const Text('No shipped sales with postal codes yet.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorOverlay({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.orange),
              const SizedBox(height: 8),
              const Text('Could not load map data.'),
              const SizedBox(height: 4),
              Text(message,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<_PostalCodePoint> points;

  const _Legend({required this.points});

  @override
  Widget build(BuildContext context) {
    final total = points.fold(0, (sum, p) => sum + p.count);
    final resolved = points.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$resolved postal code${resolved == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelSmall),
            Text('$total shipped sale${total == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
