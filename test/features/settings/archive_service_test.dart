import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/settings/services/archive_service.dart';

void main() {
  group('ArchiveService.toFirestoreMap', () {
    test('converts createdAt ISO string to Timestamp', () {
      const iso = '2026-03-15T10:30:00.000';
      final result = ArchiveService.toFirestoreMap({'createdAt': iso});
      expect(result['createdAt'], isA<Timestamp>());
      expect(
        (result['createdAt'] as Timestamp).toDate(),
        DateTime.parse(iso),
      );
    });

    test('converts scheduledDate ISO string to Timestamp', () {
      const iso = '2026-06-01T00:00:00.000';
      final result =
          ArchiveService.toFirestoreMap({'scheduledDate': iso});
      expect(result['scheduledDate'], isA<Timestamp>());
      expect(
        (result['scheduledDate'] as Timestamp).toDate(),
        DateTime.parse(iso),
      );
    });

    test('null scheduledDate passes through unchanged', () {
      final result =
          ArchiveService.toFirestoreMap({'scheduledDate': null});
      expect(result['scheduledDate'], isNull);
    });

    test('non-date string fields pass through unchanged', () {
      final result = ArchiveService.toFirestoreMap({
        'buyerName': 'Ana',
        'notes': '2026-01-01', // a date-shaped string under a non-date key
      });
      expect(result['buyerName'], 'Ana');
      expect(result['notes'], '2026-01-01');
    });

    test('recursively converts date fields in nested maps', () {
      const iso = '2026-01-01T00:00:00.000';
      final result = ArchiveService.toFirestoreMap({
        'payment': {'status': 'paid', 'method': 'mbWay'},
        'createdAt': iso,
      });
      expect(result['createdAt'], isA<Timestamp>());
      expect(result['payment'], {'status': 'paid', 'method': 'mbWay'});
    });

    test('recursively converts date fields in maps inside lists', () {
      const iso = '2026-04-20T12:00:00.000';
      final result = ArchiveService.toFirestoreMap({
        'items': [
          {'id': 'i1', 'createdAt': iso},
          {'id': 'i2', 'notes': 'no date here'},
        ],
      });
      final items = result['items'] as List;
      expect((items[0] as Map)['createdAt'], isA<Timestamp>());
      expect((items[1] as Map)['createdAt'], isNull);
      expect((items[1] as Map)['notes'], 'no date here');
    });

    test('non-map list elements pass through unchanged', () {
      final result = ArchiveService.toFirestoreMap({
        'tags': ['sale', 'urgent'],
      });
      expect(result['tags'], ['sale', 'urgent']);
    });
  });

  group('ArchiveService.importArchive version check', () {
    test('throws FormatException for unsupported version', () {
      final service = ArchiveService();
      expect(
        () => service.importArchive({
          'version': '2.0',
          'sales': <dynamic>[],
          'buyers': <dynamic>[],
        }),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('2.0'),
        )),
      );
    });

    test('throws FormatException when version is missing', () {
      final service = ArchiveService();
      expect(
        () => service.importArchive({
          'sales': <dynamic>[],
          'buyers': <dynamic>[],
        }),
        throwsA(isA<FormatException>()),
      );
    });

  });
}
