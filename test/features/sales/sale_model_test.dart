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
