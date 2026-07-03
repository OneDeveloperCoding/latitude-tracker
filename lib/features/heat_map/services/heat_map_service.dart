import 'package:latitude_tracker/features/heat_map/services/cp4_coordinates_service.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latlong2/latlong.dart';

class HeatMapPoint {
  const HeatMapPoint({
    required this.postalCode,
    required this.locality,
    required this.position,
    required this.count,
  });
  final String postalCode;
  final String locality;
  final LatLng position;
  final int count;
}

class HeatMapService {
  static final _kPostalPattern = RegExp(r'^(\d{4})-\d{3}$');

  /// Extracts the 4-digit CP4 prefix from a full Portuguese postal code
  /// (e.g. "3000-550" → "3000"). Returns null for non-PT or invalid codes.
  static String? localityPrefix(String? code) {
    if (code == null) return null;
    final match = _kPostalPattern.firstMatch(code.trim());
    return match?.group(1);
  }

  // Groups shipped sales by 4-digit locality prefix (e.g. "3000-550" → "3000").
  // Sales without a valid Portuguese postal code are excluded.
  static Map<String, int> postalCounts(List<Sale> sales) {
    final counts = <String, int>{};
    for (final sale in sales) {
      final prefix = localityPrefix(sale.shipment.postalCode);
      if ((sale.shipment.type == DeliveryType.shipping ||
              sale.shipment.type == DeliveryType.handDelivery) &&
          prefix != null) {
        counts[prefix] = (counts[prefix] ?? 0) + 1;
      }
    }
    return counts;
  }

  // Looks up coordinates for each unique locality prefix via the bundled
  // static table.
  static Future<List<HeatMapPoint>> buildPoints(List<Sale> sales) async {
    final counts = postalCounts(sales);
    final points = <HeatMapPoint>[];

    for (final entry in counts.entries) {
      final result = await Cp4CoordinatesService.lookup(entry.key);
      if (result != null) {
        points.add(
          HeatMapPoint(
            postalCode: entry.key,
            locality: result.locality,
            position: result.latLng,
            count: entry.value,
          ),
        );
      }
    }

    return points;
  }
}
