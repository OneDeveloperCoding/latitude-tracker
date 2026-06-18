import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/core/services/shared_prefs_cache.dart';
import 'package:latlong2/latlong.dart';

typedef GeocodingResult = ({LatLng latLng, String locality});
typedef _FetchResult = ({GeocodingResult? result, bool shouldCache});

class GeocodingService {
  GeocodingService._();

  static const _hitTtlDays = 180;
  // Shorter TTL for misses — retry after a week in case Nominatim gains data.
  static const _missTtlDays = 7;
  static final _cache = SharedPrefsCache('geocode_cache_v2_');

  // L1 in-memory cache. null value = known miss; absent key = not yet seen.
  static final Map<String, GeocodingResult?> _memCache = {};

  /// Pre-warms the cache for [prefixes] in the background.
  ///
  /// Skips prefixes already in the in-memory cache — safe to call on every
  /// store update. Only uncached prefixes touch SharedPreferences or the
  /// network, so re-runs are cheap once the map has been loaded once.
  static Future<void> warmUp(Iterable<String> prefixes) async {
    for (final prefix in prefixes) {
      if (_memCache.containsKey(prefix)) continue;
      await geocode(prefix);
    }
  }

  // / Returns coordinates + locality name for [postalCode], or null if not
  // found.
  /// Only makes a Nominatim request when no cached result (hit or miss) exists.
  static Future<GeocodingResult?> geocode(String postalCode) async {
    if (_memCache.containsKey(postalCode)) return _memCache[postalCode];

    final cached = await _fromCache(postalCode);
    if (cached.found) {
      _memCache[postalCode] = cached.value;
      return cached.value;
    }

    // Network — delay inside _fetchFromNominatim so cached lookups are instant.
    final (:result, :shouldCache) = await _fetchFromNominatim(postalCode);
    // Always populate _memCache so warmUp doesn't re-hit the network on the
    // next store emission. Transient errors are not persisted to SharedPrefs.
    _memCache[postalCode] = result;
    if (shouldCache) await _toCache(postalCode, result);
    return result;
  }

  static Future<({bool found, GeocodingResult? value})> _fromCache(
    String postalCode,
  ) async {
    final map = await _cache.get(
      postalCode,
      ttlDays: (m) => m['miss'] == true ? _missTtlDays : _hitTtlDays,
    );
    if (map == null) return (found: false, value: null);

    if (map['miss'] == true) return (found: true, value: null);
    return (
      found: true,
      value: (
        latLng: LatLng(map['lat'] as double, map['lng'] as double),
        locality: (map['locality'] as String?) ?? postalCode,
      ),
    );
  }

  static Future<void> _toCache(
    String postalCode,
    GeocodingResult? result,
  ) async {
    await _cache.set(
      postalCode,
      result != null
          ? {
              'lat': result.latLng.latitude,
              'lng': result.latLng.longitude,
              'locality': result.locality,
            }
          : {'miss': true},
    );
  }

  static Future<_FetchResult> _fetchFromNominatim(String postalCode) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '$postalCode Portugal',
        'format': 'json',
        'limit': '1',
        'addressdetails': '1',
      });

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'LatitudeTracker/1.0 (private)',
              'Accept-Language': 'pt,en',
            },
          )
          .timeout(const Duration(seconds: 10));

      // Honour Nominatim's 1 req/sec policy. Placed here so cached lookups
      // return immediately — the delay only fires on real network requests.
      await Future<void>.delayed(const Duration(seconds: 1));

      if (response.statusCode != 200) {
        return (result: null, shouldCache: false);
      }

      final results = jsonDecode(response.body) as List;
      if (results.isEmpty) return (result: null, shouldCache: true);

      final hit = results[0] as Map<String, dynamic>;
      final lat = double.tryParse(hit['lat'] as String? ?? '');
      final lon = double.tryParse(hit['lon'] as String? ?? '');
      if (lat == null || lon == null) return (result: null, shouldCache: false);

      final address = hit['address'] as Map<String, dynamic>? ?? {};
      final locality =
          (address['city'] as String?) ??
          (address['town'] as String?) ??
          (address['village'] as String?) ??
          (address['municipality'] as String?) ??
          (address['county'] as String?) ??
          postalCode;

      return (
        result: (latLng: LatLng(lat, lon), locality: locality),
        shouldCache: true,
      );
    } catch (e, st) {
      logError(e, st);
      return (result: null, shouldCache: false);
    }
  }
}
