import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

typedef Cp4Coordinates = ({LatLng latLng, String locality});

/// Looks up coordinates for a 4-digit Portuguese postal code prefix (CP4)
/// from a bundled static table — see docs/adr/0010-static-cp4-lookup-table.md.
///
/// No network request is made; the table is compiled offline by
/// tool/generate_cp4_table.py from CTT + OpenStreetMap data.
class Cp4CoordinatesService {
  Cp4CoordinatesService._();

  static const _assetPath = 'assets/data/cp4_coordinates.json';

  static Map<String, Cp4Coordinates>? _table;
  static Future<Map<String, Cp4Coordinates>>? _loading;

  /// Returns coordinates + locality name for [postalCode], or null if the
  /// prefix isn't in the bundled table.
  static Future<Cp4Coordinates?> lookup(String postalCode) async {
    final table = await _loadTable();
    return table[postalCode];
  }

  static Future<Map<String, Cp4Coordinates>> _loadTable() async {
    final table = _table;
    if (table != null) return table;
    _loading ??= _parseAsset().then((parsed) => _table = parsed);
    try {
      return await _loading!;
    } catch (_) {
      // Don't cache a failed load — a transient read/parse error shouldn't
      // permanently break every future lookup for the app session.
      _loading = null;
      rethrow;
    }
  }

  static Future<Map<String, Cp4Coordinates>> _parseAsset() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((cp4, value) {
      final entry = value as Map<String, dynamic>;
      return MapEntry(cp4, (
        latLng: LatLng(
          (entry['lat'] as num).toDouble(),
          (entry['lng'] as num).toDouble(),
        ),
        locality: entry['locality'] as String? ?? cp4,
      ));
    });
  }

  /// Test-only seam — replaces the table with [table] so unit tests don't
  /// depend on the real bundled asset. Call [resetOverride] afterwards.
  @visibleForTesting
  static void overrideTable(Map<String, Cp4Coordinates> table) {
    _table = table;
    _loading = null;
  }

  @visibleForTesting
  static void resetOverride() {
    _table = null;
    _loading = null;
  }
}
