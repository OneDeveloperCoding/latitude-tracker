import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin SharedPreferences-backed TTL cache.
///
/// Each instance owns a key namespace via [prefix]. The [ttlDays] callback
/// receives the stored map so callers can vary TTL on the entry's content
/// (e.g. different TTLs for cache hits vs. misses).
class SharedPrefsCache {
  final String prefix;

  SharedPrefsCache(this.prefix);

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Returns the stored map for [key] if it exists and has not expired.
  ///
  /// [ttlDays] receives the stored map and returns the TTL to apply — this
  /// lets callers vary the TTL based on entry content. Returns null and evicts
  /// the entry if expired.
  Future<Map<String, dynamic>?> get(
    String key, {
    required int Function(Map<String, dynamic>) ttlDays,
  }) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString('$prefix$key');
    if (raw == null) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(map['cachedAt'] as int);
    if (DateTime.now().difference(cachedAt).inDays > ttlDays(map)) {
      await prefs.remove('$prefix$key');
      return null;
    }
    return map;
  }

  /// Writes [data] under [key], adding a [cachedAt] timestamp automatically.
  Future<void> set(String key, Map<String, dynamic> data) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      '$prefix$key',
      jsonEncode({...data, 'cachedAt': DateTime.now().millisecondsSinceEpoch}),
    );
  }
}
