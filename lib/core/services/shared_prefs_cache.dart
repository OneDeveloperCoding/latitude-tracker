import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin SharedPreferences-backed TTL cache.
///
/// Each instance owns a key namespace via [prefix]. The `ttlDays` callback
/// receives the stored map so callers can vary TTL on the entry's content
/// (e.g. different TTLs for cache hits vs. misses).
class SharedPrefsCache {
  SharedPrefsCache(this.prefix);
  final String prefix;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Returns the stored map for [key] if it exists and has not expired.
  ///
  /// [ttlDays] receives the stored map and returns the TTL to apply — this
  /// lets callers vary the TTL based on entry content. Returns null and evicts
  /// the entry if expired. The returned map never contains the internal
  /// `cachedAt` key.
  Future<Map<String, dynamic>?> get(
    String key, {
    required int Function(Map<String, dynamic>) ttlDays,
  }) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString('$prefix$key');
    if (raw == null) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAtRaw = map['cachedAt'];
    if (cachedAtRaw is! int) {
      // Corrupt or legacy entry missing a valid timestamp — treat as expired.
      await prefs.remove('$prefix$key');
      return null;
    }
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtRaw);
    if (DateTime.now().difference(cachedAt).inDays >= ttlDays(map)) {
      await prefs.remove('$prefix$key');
      return null;
    }
    return map..remove('cachedAt');
  }

  /// Writes [data] under [key], adding a `cachedAt` timestamp automatically.
  ///
  /// [data] must not contain a `'cachedAt'` key — that key is reserved for
  /// internal TTL bookkeeping and will be injected automatically.
  Future<void> set(String key, Map<String, dynamic> data) async {
    assert(
      !data.containsKey('cachedAt'),
      'SharedPrefsCache.set: data must not contain a cachedAt key — '
      'it is reserved for internal TTL bookkeeping.',
    );
    final prefs = await _getPrefs();
    await prefs.setString(
      '$prefix$key',
      jsonEncode({...data, 'cachedAt': DateTime.now().millisecondsSinceEpoch}),
    );
  }

  /// Removes every entry under [prefix] — for one-time cleanup after a cache
  /// namespace is retired (e.g. a feature switching from a live/cached
  /// lookup to a bundled static table).
  static Future<void> purgeNamespace(String prefix) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
