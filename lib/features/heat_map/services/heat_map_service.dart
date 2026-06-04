import 'package:latlong2/latlong.dart';

import '../../sales/models/sale.dart';
import 'geocoding_service.dart';

class HeatMapPoint {
  final String postalCode;
  final String locality;
  final LatLng position;
  final int count;

  const HeatMapPoint({
    required this.postalCode,
    required this.locality,
    required this.position,
    required this.count,
  });
}

class HeatMapService {
  static final _kPostalPattern = RegExp(r'^(\d{4})-\d{3}$');

  // Groups shipped sales by 4-digit locality prefix (e.g. "3000-550" → "3000").
  // Sales without a valid Portuguese postal code are excluded.
  static Map<String, int> postalCounts(List<Sale> sales) {
    final counts = <String, int>{};
    for (final sale in sales) {
      final prefix = _localityPrefix(sale.shipment.postalCode);
      if ((sale.shipment.type == DeliveryType.shipping ||
              sale.shipment.type == DeliveryType.handDelivery) &&
          prefix != null) {
        counts[prefix] = (counts[prefix] ?? 0) + 1;
      }
    }
    return counts;
  }

  // Geocodes each unique locality prefix. Rate limiting and caching are
  // handled by [GeocodingService] — cached prefixes return immediately.
  // [onProgress] receives a human-readable status string and progress counts.
  static Future<List<HeatMapPoint>> buildPoints(
    List<Sale> sales, {
    void Function(String status, int done, int total)? onProgress,
  }) async {
    final counts = postalCounts(sales);
    final points = <HeatMapPoint>[];
    var done = 0;

    for (final entry in counts.entries) {
      onProgress?.call('Locating ${entry.key}', done, counts.length);

      final result = await GeocodingService.geocode(entry.key);
      if (result != null) {
        points.add(HeatMapPoint(
          postalCode: entry.key,
          locality: result.locality,
          position: result.latLng,
          count: entry.value,
        ));
      }

      done++;
    }

    return points;
  }

  static String? _localityPrefix(String? code) {
    if (code == null) return null;
    final match = _kPostalPattern.firstMatch(code.trim());
    return match?.group(1);
  }
}
