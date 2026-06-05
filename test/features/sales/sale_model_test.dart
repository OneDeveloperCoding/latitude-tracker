import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

ComponentItem _component(String id, {required bool available}) =>
    ComponentItem(id: id, name: id, isAvailable: available);

void main() {
  group('SaleItem.deriveAssemblyStatus', () {
    test('waitingForMaterials is never changed', () {
      final allAvailable = [_component('a', available: true)];
      expect(
        SaleItem.deriveAssemblyStatus(
            allAvailable, AssemblyStatus.waitingForMaterials),
        AssemblyStatus.waitingForMaterials,
      );
    });

    test('notStarted + all available → ready', () {
      final components = [
        _component('a', available: true),
        _component('b', available: true),
      ];
      expect(
        SaleItem.deriveAssemblyStatus(components, AssemblyStatus.notStarted),
        AssemblyStatus.ready,
      );
    });

    test('inProgress + all available → ready', () {
      final components = [_component('a', available: true)];
      expect(
        SaleItem.deriveAssemblyStatus(components, AssemblyStatus.inProgress),
        AssemblyStatus.ready,
      );
    });

    test('ready + some unavailable → inProgress', () {
      final components = [
        _component('a', available: true),
        _component('b', available: false),
      ];
      expect(
        SaleItem.deriveAssemblyStatus(components, AssemblyStatus.ready),
        AssemblyStatus.inProgress,
      );
    });

    test('notStarted + some unavailable stays notStarted', () {
      final components = [_component('a', available: false)];
      expect(
        SaleItem.deriveAssemblyStatus(components, AssemblyStatus.notStarted),
        AssemblyStatus.notStarted,
      );
    });

    test('empty components + notStarted stays notStarted', () {
      // allAvailable requires isNotEmpty — empty list is treated as not ready.
      expect(
        SaleItem.deriveAssemblyStatus(const [], AssemblyStatus.notStarted),
        AssemblyStatus.notStarted,
      );
    });

    test('empty components + ready → inProgress', () {
      // If all components were removed after the assembly was marked ready,
      // it reverts to inProgress.
      expect(
        SaleItem.deriveAssemblyStatus(const [], AssemblyStatus.ready),
        AssemblyStatus.inProgress,
      );
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
  });

  group('Sale.totalPrice', () {
    test('sums all item prices', () {
      final sale = Sale(
        id: 'test',
        buyerId: 'b1',
        buyerName: 'Test',
        items: [
          SaleItem(
              id: '1',
              description: 'a',
              category: 'x',
              price: 10.0,
              assemblyStatus: AssemblyStatus.ready),
          SaleItem(
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
