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

    test('malformed createdAt string falls back to epoch rather than throwing', () {
      final map = _baseRepairMap()..['createdAt'] = 'not-a-date';
      expect(() => Repair.fromArchiveMap(map), returnsNormally);
      expect(Repair.fromArchiveMap(map).createdAt, DateTime.fromMillisecondsSinceEpoch(0));
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

  group('RepairReturnDelivery — toMap / fromMap round-trip', () {
    test('all fields survive toMap → fromMap', () {
      const original = RepairReturnDelivery(
        type: DeliveryType.handDelivery,
        status: ShipmentStatus.delivered,
        trackingCode: 'PT123456789PT',
        postalCode: '4700-200',
      );
      final restored = RepairReturnDelivery.fromMap(original.toMap());
      expect(restored.type, original.type);
      expect(restored.status, original.status);
      expect(restored.trackingCode, original.trackingCode);
      expect(restored.postalCode, original.postalCode);
    });

    test('null optional fields survive round-trip', () {
      const original = RepairReturnDelivery(
        type: DeliveryType.shipping,
        status: ShipmentStatus.pending,
      );
      final restored = RepairReturnDelivery.fromMap(original.toMap());
      expect(restored.trackingCode, isNull);
      expect(restored.postalCode, isNull);
    });
  });

  group('Repair.fromArchiveMap — full field preservation', () {
    test('all scalar fields are read correctly', () {
      final map = _baseRepairMap()
        ..['workDone'] = 'Replaced clasp'
        ..['materialsCost'] = 5.50
        ..['linkedSaleId'] = 's1'
        ..['freeTextContact'] = null
        ..['photoUrls'] = ['https://example.com/photo.jpg'];
      final repair = Repair.fromArchiveMap(map);
      expect(repair.id, 'r1');
      expect(repair.buyerId, 'b1');
      expect(repair.buyerName, 'Ana');
      expect(repair.itemDescription, 'Necklace');
      expect(repair.itemCategory, 'Colares');
      expect(repair.problemDescription, 'Broken clasp');
      expect(repair.workDone, 'Replaced clasp');
      expect(repair.materialsCost, 5.50);
      expect(repair.linkedSaleId, 's1');
      expect(repair.photoUrls, ['https://example.com/photo.jpg']);
      expect(repair.createdAt, DateTime(2026, 1, 1));
    });

    test('materialsCost parsed as double when stored as int', () {
      final map = _baseRepairMap()..['materialsCost'] = 10;
      expect(Repair.fromArchiveMap(map).materialsCost, 10.0);
    });

    test('photoUrls absent falls back to empty list', () {
      final map = _baseRepairMap()..remove('photoUrls');
      expect(Repair.fromArchiveMap(map).photoUrls, isEmpty);
    });
  });

  group('Repair — computed properties', () {
    Repair makeRepair({
      RepairStatus status = RepairStatus.inProgress,
      ShipmentStatus returnStatus = ShipmentStatus.pending,
      String? buyerId = 'b1',
      String? buyerName = 'Ana',
      String? freeTextContact,
    }) =>
        Repair(
          id: 'r1',
          buyerId: buyerId,
          buyerName: buyerName,
          freeTextContact: freeTextContact,
          itemDescription: 'Necklace',
          itemCategory: 'Colares',
          problemDescription: 'Broken clasp',
          status: status,
          payment: const SalePayment(
              status: PaymentStatus.unpaid, method: PaymentMethod.cash),
          returnDelivery: RepairReturnDelivery(
              type: DeliveryType.shipping, status: returnStatus),
          createdAt: DateTime(2026, 1, 1),
        );

    group('isActive', () {
      test('not returned → active', () {
        expect(makeRepair(status: RepairStatus.inProgress).isActive, isTrue);
      });

      test('returned + pending delivery → still active', () {
        expect(
          makeRepair(
            status: RepairStatus.returned,
            returnStatus: ShipmentStatus.pending,
          ).isActive,
          isTrue,
        );
      });

      test('returned + delivered → inactive', () {
        expect(
          makeRepair(
            status: RepairStatus.returned,
            returnStatus: ShipmentStatus.delivered,
          ).isActive,
          isFalse,
        );
      });
    });

    group('contactName', () {
      test('buyerName takes priority', () {
        expect(makeRepair(buyerName: 'Ana').contactName, 'Ana');
      });

      test('freeTextContact used when no buyerName', () {
        expect(
          makeRepair(
            buyerId: null,
            buyerName: null,
            freeTextContact: 'Maria Instagram',
          ).contactName,
          'Maria Instagram',
        );
      });

      test('returns empty string when buyerName is null and buyerId is set', () {
        // freeTextContact stays null here because buyerId is non-null, which
        // satisfies the constructor assert without needing freeTextContact.
        expect(makeRepair(buyerName: null).contactName, '');
      });
    });

    group('isLinkedToBuyer', () {
      test('has buyerId → linked', () {
        expect(makeRepair(buyerId: 'b1').isLinkedToBuyer, isTrue);
      });

      test('no buyerId → not linked', () {
        expect(
          makeRepair(buyerId: null, freeTextContact: 'Maria').isLinkedToBuyer,
          isFalse,
        );
      });
    });
  });

  group('Repair.copyWith', () {
    final base = Repair(
      id: 'r1',
      buyerId: 'b1',
      buyerName: 'Ana',
      itemDescription: 'Necklace',
      itemCategory: 'Colares',
      problemDescription: 'Broken clasp',
      status: RepairStatus.inProgress,
      payment: const SalePayment(
          status: PaymentStatus.unpaid, method: PaymentMethod.cash),
      returnDelivery: const RepairReturnDelivery(
          type: DeliveryType.shipping, status: ShipmentStatus.pending),
      createdAt: DateTime(2026, 1, 1),
    );

    test('status updated, other fields preserved', () {
      final updated = base.copyWith(status: RepairStatus.done);
      expect(updated.status, RepairStatus.done);
      expect(updated.id, base.id);
      expect(updated.itemDescription, base.itemDescription);
    });

    test('materialsCost can be set to null via copyWith', () {
      final withCost = base.copyWith(materialsCost: 12.0);
      final cleared = withCost.copyWith(materialsCost: null);
      expect(cleared.materialsCost, isNull);
    });

    test('contact fields are immutable (not in copyWith)', () {
      // buyerId/buyerName/freeTextContact are intentionally excluded.
      final updated = base.copyWith(workDone: 'Repaired');
      expect(updated.buyerId, base.buyerId);
      expect(updated.buyerName, base.buyerName);
    });
  });
}
