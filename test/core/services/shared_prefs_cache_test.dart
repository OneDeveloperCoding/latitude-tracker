import 'dart:convert';

import 'package:latitude_tracker/core/services/shared_prefs_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPrefsCache.get', () {
    test('returns null when key is absent', () async {
      final cache = SharedPrefsCache('test_');
      final result = await cache.get('missing', ttlDays: (_) => 30);
      expect(result, isNull);
    });

    test('returns stored map when entry is within TTL', () async {
      final cache = SharedPrefsCache('test_');
      await cache.set('key', {'value': 42});

      final result = await cache.get('key', ttlDays: (_) => 30);

      expect(result, isNotNull);
      expect(result!['value'], 42);
    });

    test('returns null and evicts entry when TTL is exceeded', () async {
      final prefs = await SharedPreferences.getInstance();
      const key = 'old_entry';
      final expired = DateTime.now().subtract(const Duration(days: 31));
      await prefs.setString(
        'test_$key',
        jsonEncode({'value': 1, 'cachedAt': expired.millisecondsSinceEpoch}),
      );

      final cache = SharedPrefsCache('test_');
      final result = await cache.get(key, ttlDays: (_) => 30);

      expect(result, isNull);
      expect(prefs.getString('test_$key'), isNull);
    });

    test('evicts entry aged exactly ttlDays days (boundary: >= not >)', () async {
      final prefs = await SharedPreferences.getInstance();
      const key = 'boundary';
      final exactlyOnBoundary = DateTime.now().subtract(const Duration(days: 30));
      await prefs.setString(
        'test_$key',
        jsonEncode({'value': 1, 'cachedAt': exactlyOnBoundary.millisecondsSinceEpoch}),
      );

      final cache = SharedPrefsCache('test_');
      final result = await cache.get(key, ttlDays: (_) => 30);

      expect(result, isNull);
      expect(prefs.getString('test_$key'), isNull);
    });

    test('evicts and returns null for entry with missing cachedAt', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_no_ts', jsonEncode({'value': 1}));

      final cache = SharedPrefsCache('test_');
      final result = await cache.get('no_ts', ttlDays: (_) => 30);

      expect(result, isNull);
      expect(prefs.getString('test_no_ts'), isNull);
    });

    test('evicts and returns null for entry with non-int cachedAt', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'test_bad_ts',
        jsonEncode({'value': 1, 'cachedAt': 'not-a-number'}),
      );

      final cache = SharedPrefsCache('test_');
      final result = await cache.get('bad_ts', ttlDays: (_) => 30);

      expect(result, isNull);
      expect(prefs.getString('test_bad_ts'), isNull);
    });

    test('does not include cachedAt in the returned map', () async {
      final cache = SharedPrefsCache('test_');
      await cache.set('key', {'value': 99});

      final result = await cache.get('key', ttlDays: (_) => 30);

      expect(result, isNotNull);
      expect(result!.containsKey('cachedAt'), isFalse);
      expect(result['value'], 99);
    });

    test('respects TTL returned by callback based on map content', () async {
      final prefs = await SharedPreferences.getInstance();
      final recent = DateTime.now().subtract(const Duration(days: 10));

      // A 'miss' entry (TTL = 7 days) — should be evicted after 10 days.
      await prefs.setString(
        'test_miss',
        jsonEncode({'miss': true, 'cachedAt': recent.millisecondsSinceEpoch}),
      );
      // A 'hit' entry (TTL = 180 days) — should still be valid after 10 days.
      await prefs.setString(
        'test_hit',
        jsonEncode({'value': 'ok', 'cachedAt': recent.millisecondsSinceEpoch}),
      );

      final cache = SharedPrefsCache('test_');
      int ttlResolver(Map<String, dynamic> m) =>
          m['miss'] == true ? 7 : 180;

      final missResult = await cache.get('miss', ttlDays: ttlResolver);
      final hitResult = await cache.get('hit', ttlDays: ttlResolver);

      expect(missResult, isNull);
      expect(hitResult, isNotNull);
      expect(hitResult!['value'], 'ok');
    });

    test('entries from different prefixes do not collide', () async {
      final cacheA = SharedPrefsCache('a_');
      final cacheB = SharedPrefsCache('b_');

      await cacheA.set('key', {'from': 'a'});

      final fromA = await cacheA.get('key', ttlDays: (_) => 30);
      final fromB = await cacheB.get('key', ttlDays: (_) => 30);

      expect(fromA!['from'], 'a');
      expect(fromB, isNull);
    });
  });

  group('SharedPrefsCache.set', () {
    test('adds cachedAt timestamp automatically', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      final cache = SharedPrefsCache('test_');
      await cache.set('key', {'x': 1});
      final after = DateTime.now().millisecondsSinceEpoch;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('test_key')!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = map['cachedAt'] as int;

      expect(cachedAt, greaterThanOrEqualTo(before));
      expect(cachedAt, lessThanOrEqualTo(after));
    });

    test('overwrites a previous entry for the same key', () async {
      final cache = SharedPrefsCache('test_');
      await cache.set('key', {'v': 1});
      await cache.set('key', {'v': 2});

      final result = await cache.get('key', ttlDays: (_) => 30);
      expect(result!['v'], 2);
    });

    test('asserts when data contains reserved cachedAt key', () async {
      final cache = SharedPrefsCache('test_');
      expect(
        () => cache.set('key', {'value': 1, 'cachedAt': 12345}),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
