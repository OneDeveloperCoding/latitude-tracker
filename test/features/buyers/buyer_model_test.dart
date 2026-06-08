import 'package:test/test.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';

void main() {
  group('Buyer.fromArchiveMap', () {
    test('maps all fields from a well-formed archive map', () {
      final buyer = Buyer.fromArchiveMap({
        'id': 'b1',
        'name': 'Ana Silva',
        'instagramHandle': '@ana',
        'phone': '+351910000000',
        'nif': '123456789',
        'tags': ['vip', 'regular'],
        'notes': 'Prefers blue',
        'createdAt': '2025-03-15T10:30:00.000',
      });
      expect(buyer.id, 'b1');
      expect(buyer.name, 'Ana Silva');
      expect(buyer.instagramHandle, '@ana');
      expect(buyer.phone, '+351910000000');
      expect(buyer.nif, '123456789');
      expect(buyer.tags, ['vip', 'regular']);
      expect(buyer.notes, 'Prefers blue');
      expect(buyer.createdAt, DateTime.parse('2025-03-15T10:30:00.000'));
    });

    test('null optional fields are preserved as null', () {
      final buyer = Buyer.fromArchiveMap({
        'id': 'b1',
        'name': 'Ana',
        'createdAt': '2025-01-01T00:00:00.000',
      });
      expect(buyer.instagramHandle, isNull);
      expect(buyer.phone, isNull);
      expect(buyer.nif, isNull);
      expect(buyer.notes, isNull);
      expect(buyer.tags, isEmpty);
    });

    test('missing name defaults to empty string', () {
      final buyer = Buyer.fromArchiveMap({
        'id': 'b1',
        'createdAt': '2025-01-01T00:00:00.000',
      });
      expect(buyer.name, '');
    });

    test('missing id defaults to empty string', () {
      final buyer = Buyer.fromArchiveMap({
        'name': 'Ana',
        'createdAt': '2025-01-01T00:00:00.000',
      });
      expect(buyer.id, '');
    });

    test('unparseable createdAt falls back to epoch', () {
      final buyer = Buyer.fromArchiveMap({
        'id': 'b1',
        'name': 'Ana',
        'createdAt': 'not-a-date',
      });
      expect(buyer.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('missing createdAt falls back to epoch', () {
      final buyer = Buyer.fromArchiveMap({'id': 'b1', 'name': 'Ana'});
      expect(buyer.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
