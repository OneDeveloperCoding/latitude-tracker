import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  // In-memory cache persists for the app session — avoids re-geocoding the
  // same postal code twice and keeps requests well under Nominatim rate limits.
  static final Map<String, LatLng?> _cache = {};

  static Future<LatLng?> geocode(String postalCode) async {
    if (_cache.containsKey(postalCode)) return _cache[postalCode];

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '$postalCode Portugal',
        'format': 'json',
        'limit': '1',
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'LatitudeTracker/1.0 (private)',
        'Accept-Language': 'pt,en',
      });

      if (response.statusCode != 200) {
        _cache[postalCode] = null;
        return null;
      }

      final results = jsonDecode(response.body) as List;
      if (results.isEmpty) {
        _cache[postalCode] = null;
        return null;
      }

      final lat = double.tryParse(results[0]['lat'] as String? ?? '');
      final lon = double.tryParse(results[0]['lon'] as String? ?? '');
      final latLng =
          (lat != null && lon != null) ? LatLng(lat, lon) : null;

      _cache[postalCode] = latLng;
      return latLng;
    } catch (_) {
      _cache[postalCode] = null;
      return null;
    }
  }
}
