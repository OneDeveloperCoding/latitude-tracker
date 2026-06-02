import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PostalCodeResult {
  final List<String> streets;
  final String city;

  const PostalCodeResult({required this.streets, required this.city});
}

class PostalCodeService {
  PostalCodeService._();

  static const _ttlDays = 180;
  static const _cachePrefix = 'postal_cache_v2_';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  static Future<PostalCodeResult?> lookup(String postalCode) async {
    final cached = await _fromCache(postalCode);
    if (cached != null) return cached;

    final result = await _fetchFromApi(postalCode);
    if (result != null) await _toCache(postalCode, result);
    return result;
  }

  static Future<PostalCodeResult?> _fromCache(String postalCode) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString('$_cachePrefix$postalCode');
    if (raw == null) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(map['cachedAt'] as int);
    if (DateTime.now().difference(cachedAt).inDays > _ttlDays) {
      await prefs.remove('$_cachePrefix$postalCode');
      return null;
    }

    return PostalCodeResult(
      streets: (map['streets'] as List<dynamic>).cast<String>(),
      city: map['city'] as String,
    );
  }

  static Future<void> _toCache(String postalCode, PostalCodeResult result) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      '$_cachePrefix$postalCode',
      jsonEncode({
        'streets': result.streets,
        'city': result.city,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  static Future<PostalCodeResult?> _fetchFromApi(String postalCode) async {
    try {
      final uri = Uri.parse('https://json.geoapi.pt/cp/$postalCode');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final parts = (data['partes'] as List<dynamic>? ?? []);
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
    } catch (_) {
      return null;
    }
  }
}
