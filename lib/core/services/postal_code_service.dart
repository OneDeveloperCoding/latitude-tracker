import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/core/services/shared_prefs_cache.dart';

class PostalCodeResult {

  const PostalCodeResult({required this.streets, required this.city});
  final List<String> streets;
  final String city;
}

class PostalCodeService {
  PostalCodeService._();

  static const _ttlDays = 180;
  static final _cache = SharedPrefsCache('postal_cache_v2_');

  static Future<PostalCodeResult?> lookup(String postalCode) async {
    final cached = await _fromCache(postalCode);
    if (cached != null) return cached;

    final result = await _fetchFromApi(postalCode);
    if (result != null) await _toCache(postalCode, result);
    return result;
  }

  static Future<PostalCodeResult?> _fromCache(String postalCode) async {
    final map = await _cache.get(postalCode, ttlDays: (_) => _ttlDays);
    if (map == null) return null;

    return PostalCodeResult(
      streets: (map['streets'] as List<dynamic>).cast<String>(),
      city: map['city'] as String,
    );
  }

  static Future<void> _toCache(String postalCode, PostalCodeResult result) async {
    await _cache.set(postalCode, {
      'streets': result.streets,
      'city': result.city,
    });
  }

  static Future<PostalCodeResult?> _fetchFromApi(String postalCode) async {
    try {
      final uri = Uri.parse('https://json.geoapi.pt/cp/$postalCode');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final parts = data['partes'] as List<dynamic>? ?? [];
      final streets = parts
          .map((p) =>
              ((p as Map<String, dynamic>)['Artéria'] as String? ?? '').trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      final city = ((data['Localidade'] as String?)?.trim().isNotEmpty == true
              ? data['Localidade'] as String
              : data['Concelho'] as String? ?? '')
          .trim();

      if (city.isEmpty) return null;
      return PostalCodeResult(streets: streets, city: city);
    } catch (e, st) {
      logError(e, st);
      return null;
    }
  }
}
