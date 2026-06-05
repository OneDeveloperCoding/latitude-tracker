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

  group('Repair.fromArchiveMap — null sub-maps use defaults', () {
    test('null payment sub-map uses defaults', () {
      final map = _baseRepairMap()..['payment'] = null;
      final repair = Repair.fromArchiveMap(map);
      expect(repair.payment.status, PaymentStatus.unpaid);
      expect(repair.payment.method, PaymentMethod.cash);
    });

    test('null returnDelivery sub-map uses defaults', () {
      final map = _baseRepairMap()..['returnDelivery'] = null;
      final repair = Repair.fromArchiveMap(map);
      expect(repair.returnDelivery.type, DeliveryType.shipping);
      expect(repair.returnDelivery.status, ShipmentStatus.pending);
    });

    test('missing createdAt falls back to epoch, not current time', () {
      final map = _baseRepairMap()..['createdAt'] = null;
      final repair = Repair.fromArchiveMap(map);
      expect(repair.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('both buyerId and freeTextContact absent does not throw', () {
      final map = _baseRepairMap()
        ..remove('buyerId')
        ..['freeTextContact'] = null;
      expect(() => Repair.fromArchiveMap(map), returnsNormally);
      expect(Repair.fromArchiveMap(map).freeTextContact, '');
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
