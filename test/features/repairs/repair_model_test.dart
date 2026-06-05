import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

Map<String, dynamic> _baseRepairMap() => {
      'id': 'r1',
      'buyerId': 'b1',
      'buyerName': 'Ana',
      'itemDescription': 'Necklace',
      'itemCategory': 'Colares',
      'problemDescription': 'Broken clasp',
      'status': 'received',
      'payment': {'status': 'unpaid', 'method': 'cash'},
      'returnDelivery': {'type': 'shipping', 'status': 'pending'},
      'createdAt': '2026-01-01T00:00:00.000',
    };

void main() {
  group('Repair.fromArchiveMap — unknown enum falls back to default', () {
    test('unknown status falls back to received', () {
      final map = _baseRepairMap()..['status'] = 'legacyStatus';
      expect(Repair.fromArchiveMap(map).status, RepairStatus.received);
    });

    test('null status falls back to received', () {
      final map = _baseRepairMap()..['status'] = null;
      expect(Repair.fromArchiveMap(map).status, RepairStatus.received);
    });
  });

  group('Repair.fromArchiveMap — null-safe string fields', () {
    test('null itemDescription falls back to empty string', () {
      final map = _baseRepairMap()..['itemDescription'] = null;
      expect(Repair.fromArchiveMap(map).itemDescription, '');
    });

    test('null itemCategory falls back to empty string', () {
      final map = _baseRepairMap()..['itemCategory'] = null;
      expect(Repair.fromArchiveMap(map).itemCategory, '');
    });

    test('null problemDescription falls back to empty string', () {
      final map = _baseRepairMap()..['problemDescription'] = null;
      expect(Repair.fromArchiveMap(map).problemDescription, '');
    });
  });

  group('RepairReturnDelivery.fromMap — unknown enum falls back to default', () {
    test('unknown status falls back to pending', () {
      final map = {'type': 'shipping', 'status': 'legacyStatus'};
      expect(
        RepairReturnDelivery.fromMap(map).status,
        ShipmentStatus.pending,
      );
    });

    test('null status falls back to pending', () {
      final map = {'type': 'shipping', 'status': null};
      expect(
        RepairReturnDelivery.fromMap(map).status,
        ShipmentStatus.pending,
      );
    });
  });
}
