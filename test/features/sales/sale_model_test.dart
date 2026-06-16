import 'package:test/test.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

ComponentItem _component(String id, {required bool available, int quantity = 1}) =>
    ComponentItem(id: id, name: id, quantity: quantity, isAvailable: available);

void main() {
  group('AssemblyStatus is fully manual', () {
    test('updating components via copyWith never changes assemblyStatus', () {
      final item = SaleItem(
        id: 'i1',
        description: 'test',
        category: 'x',
        price: 10,
        assemblyStatus: AssemblyStatus.notStarted,
        components: [_component('a', available: false)],
      );
      final allAvailable = item.copyWith(
        components: [_component('a', available: true)],
      );
      expect(allAvailable.assemblyStatus, AssemblyStatus.notStarted,
          reason: 'assemblyStatus must not auto-derive from component availability');
    });

    test('adjustedQuantity clamps to [1, kMaxComponentQuantity]', () {
      final c = _component('a', available: false, quantity: 2);
      expect(c.adjustedQuantity(1).quantity, 3);
      expect(c.adjustedQuantity(-1).quantity, 1);
      expect(c.adjustedQuantity(-5).quantity, 1);
      expect(c.adjustedQuantity(148).quantity, 150);
      final atMax = _component('a', available: false, quantity: kMaxComponentQuantity);
      expect(atMax.adjustedQuantity(1).quantity, kMaxComponentQuantity);
    });
  });

  group('ComponentItem.quantity', () {
    test('defaults to 1 when not provided', () {
      const c = ComponentItem(id: 'x', name: 'x', isAvailable: false);
      expect(c.quantity, 1);
    });

    test('round-trips through toMap / fromMap', () {
      final original = _component('a', available: false, quantity: 3);
      final restored = ComponentItem.fromMap(original.toMap());
      expect(restored.quantity, 3);
      expect(restored.isAvailable, false);
    });

    test('fromMap defaults quantity to 1 when field is absent', () {
      final map = {'id': 'a', 'name': 'a', 'isAvailable': false};
      expect(ComponentItem.fromMap(map).quantity, 1);
    });

    test('copyWith updates quantity independently', () {
      final original = _component('a', available: false, quantity: 2);
      final updated = original.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.isAvailable, false);
      expect(updated.name, 'a');
    });
  });

  group('Sale.derivedAssemblyStatus', () {
    Sale saleWith(List<AssemblyStatus> statuses) => Sale(
          id: 'test',
          buyerId: 'b1',
          buyerName: 'Test',
          items: statuses
              .map((s) => SaleItem(
                    id: s.name,
                    description: s.name,
                    category: 'x',
                    price: 1,
                    assemblyStatus: s,
                  ))
              .toList(),
          payment: const SalePayment(
              status: PaymentStatus.paid, method: PaymentMethod.mbWay),
          shipment: const SaleShipment(
              type: DeliveryType.shipping, status: ShipmentStatus.pending),
          requiresNif: false,
          createdAt: DateTime(2026, 1, 1),
        );

    test('all ready → ready', () {
      expect(
        saleWith([AssemblyStatus.ready, AssemblyStatus.ready])
            .derivedAssemblyStatus,
        AssemblyStatus.ready,
      );
    });

    test('one waitingForMaterials → waitingForMaterials (worst)', () {
      expect(
        saleWith([AssemblyStatus.ready, AssemblyStatus.waitingForMaterials])
            .derivedAssemblyStatus,
        AssemblyStatus.waitingForMaterials,
      );
    });

    test('inProgress beats notStarted', () {
      expect(
        saleWith([AssemblyStatus.notStarted, AssemblyStatus.inProgress])
            .derivedAssemblyStatus,
        AssemblyStatus.inProgress,
      );
    });

    test('notStarted wins over ready', () {
      expect(
        saleWith([AssemblyStatus.ready, AssemblyStatus.notStarted])
            .derivedAssemblyStatus,
        AssemblyStatus.notStarted,
      );
    });

    test('empty items → notStarted', () {
      expect(
        saleWith([]).derivedAssemblyStatus,
        AssemblyStatus.notStarted,
      );
    });
  });

  group('SalePayment round-trip serialisation', () {
    for (final method in PaymentMethod.values) {
      test('${method.name} survives toMap → fromMap', () {
        final original =
            SalePayment(status: PaymentStatus.paid, method: method);
        final restored = SalePayment.fromMap(original.toMap());
        expect(restored.method, method);
        expect(restored.status, PaymentStatus.paid);
      });
    }
  });

  group('SaleItem.fromMap — unknown enum falls back to default', () {
    Map<String, dynamic> baseItemMap() => {
          'id': 'i1',
          'description': 'Test',
          'category': 'Colares',
          'price': 10.0,
          'assemblyStatus': 'notStarted',
        };

    test('unknown assemblyStatus falls back to notStarted', () {
      final map = baseItemMap()..['assemblyStatus'] = 'obsoleteStatus';
      expect(SaleItem.fromMap(map).assemblyStatus, AssemblyStatus.notStarted);
    });

    test('null assemblyStatus falls back to notStarted', () {
      final map = baseItemMap()..['assemblyStatus'] = null;
      expect(SaleItem.fromMap(map).assemblyStatus, AssemblyStatus.notStarted);
    });

    test('null id falls back to empty string', () {
      final map = baseItemMap()..['id'] = null;
      expect(SaleItem.fromMap(map).id, '');
    });

    test('null description falls back to empty string', () {
      final map = baseItemMap()..['description'] = null;
      expect(SaleItem.fromMap(map).description, '');
    });
  });

  group('SalePayment.fromMap — unknown enum falls back to default', () {
    test('unknown status falls back to unpaid', () {
      final map = {'status': 'legacyStatus', 'method': 'mbWay'};
      expect(SalePayment.fromMap(map).status, PaymentStatus.unpaid);
    });

    test('unknown method falls back to cash', () {
      final map = {'status': 'paid', 'method': 'legacyMethod'};
      expect(SalePayment.fromMap(map).method, PaymentMethod.cash);
    });

    test('null status falls back to unpaid', () {
      final map = {'status': null, 'method': 'mbWay'};
      expect(SalePayment.fromMap(map).status, PaymentStatus.unpaid);
    });

    test('null method falls back to cash', () {
      final map = {'status': 'paid', 'method': null};
      expect(SalePayment.fromMap(map).method, PaymentMethod.cash);
    });
  });

  group('SaleShipment.fromMap — unknown enum falls back to default', () {
    Map<String, dynamic> baseShipmentMap() =>
        {'type': 'shipping', 'status': 'pending'};

    test('unknown status falls back to pending', () {
      final map = baseShipmentMap()..['status'] = 'legacyStatus';
      expect(SaleShipment.fromMap(map).status, ShipmentStatus.pending);
    });

    test('null status falls back to pending', () {
      final map = baseShipmentMap()..['status'] = null;
      expect(SaleShipment.fromMap(map).status, ShipmentStatus.pending);
    });
  });

  group('SaleItem.fromMap — null price falls back to 0.0', () {
    test('null price falls back to 0.0', () {
      final map = {
        'id': 'i1',
        'description': 'Test',
        'category': 'Colares',
        'price': null,
        'assemblyStatus': 'notStarted',
      };
      expect(SaleItem.fromMap(map).price, 0.0);
    });
  });

  group('SalePayment.fromMap — missing sub-map uses defaults', () {
    test('empty map falls back to unpaid + cash', () {
      final payment = SalePayment.fromMap(const {});
      expect(payment.status, PaymentStatus.unpaid);
      expect(payment.method, PaymentMethod.cash);
    });
  });

  group('SaleShipment.fromMap — missing sub-map uses defaults', () {
    test('empty map falls back to shipping + pending', () {
      final shipment = SaleShipment.fromMap(const {});
      expect(shipment.type, DeliveryType.shipping);
      expect(shipment.status, ShipmentStatus.pending);
    });
  });

  group('Sale.fromArchiveMap — null-safe string and enum fields', () {
    Map<String, dynamic> baseSaleMap() => {
          'id': 's1',
          'buyerId': 'b1',
          'buyerName': 'Ana',
          'items': <dynamic>[],
          'payment': {'status': 'paid', 'method': 'mbWay'},
          'shipment': {'type': 'shipping', 'status': 'pending'},
          'requiresNif': false,
          'atSubmissionDone': false,
          'createdAt': '2026-01-01T00:00:00.000',
        };

    test('null buyerId falls back to empty string', () {
      final map = baseSaleMap()..['buyerId'] = null;
      expect(Sale.fromArchiveMap(map).buyerId, '');
    });

    test('null buyerName falls back to empty string', () {
      final map = baseSaleMap()..['buyerName'] = null;
      expect(Sale.fromArchiveMap(map).buyerName, '');
    });

    test('null payment sub-map uses defaults', () {
      final map = baseSaleMap()..['payment'] = null;
      final sale = Sale.fromArchiveMap(map);
      expect(sale.payment.status, PaymentStatus.unpaid);
      expect(sale.payment.method, PaymentMethod.cash);
    });

    test('null shipment sub-map uses defaults', () {
      final map = baseSaleMap()..['shipment'] = null;
      final sale = Sale.fromArchiveMap(map);
      expect(sale.shipment.type, DeliveryType.shipping);
      expect(sale.shipment.status, ShipmentStatus.pending);
    });

    test('missing createdAt falls back to epoch, not current time', () {
      final map = baseSaleMap()..['createdAt'] = null;
      final sale = Sale.fromArchiveMap(map);
      expect(sale.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('malformed createdAt string falls back to epoch rather than throwing', () {
      final map = baseSaleMap()..['createdAt'] = 'not-a-date';
      expect(() => Sale.fromArchiveMap(map), returnsNormally);
      expect(Sale.fromArchiveMap(map).createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('Sale.totalPrice', () {
    test('sums all item prices', () {
      final sale = Sale(
        id: 'test',
        buyerId: 'b1',
        buyerName: 'Test',
        items: [
          const SaleItem(
              id: '1',
              description: 'a',
              category: 'x',
              price: 10.0,
              assemblyStatus: AssemblyStatus.ready),
          const SaleItem(
              id: '2',
              description: 'b',
              category: 'x',
              price: 25.50,
              assemblyStatus: AssemblyStatus.ready),
        ],
        payment: const SalePayment(
            status: PaymentStatus.paid, method: PaymentMethod.mbWay),
        shipment: const SaleShipment(
            type: DeliveryType.shipping, status: ShipmentStatus.pending),
        requiresNif: false,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(sale.totalPrice, 35.50);
    });

    test('empty items → 0.0', () {
      final sale = Sale(
        id: 'test',
        buyerId: 'b1',
        buyerName: 'Test',
        items: const [],
        payment: const SalePayment(
            status: PaymentStatus.paid, method: PaymentMethod.mbWay),
        shipment: const SaleShipment(
            type: DeliveryType.shipping, status: ShipmentStatus.pending),
        requiresNif: false,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(sale.totalPrice, 0.0);
    });
  });
}
