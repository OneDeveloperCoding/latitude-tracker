import 'package:test/test.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency.dart';
import 'package:latitude_tracker/features/sales/services/shopping_list_aggregator.dart';

import '../../helpers/sale_factory.dart';

ComponentItem makeComponent({
  String id = 'c1',
  String name = 'blue bead',
  int quantity = 1,
  bool isAvailable = false,
  String? notes,
  List<String> photoUrls = const [],
}) =>
    ComponentItem(
      id: id,
      name: name,
      quantity: quantity,
      isAvailable: isAvailable,
      notes: notes,
      photoUrls: photoUrls,
    );

void main() {
  group('aggregateShoppingList', () {
    test('returns empty when no sales', () {
      expect(aggregateShoppingList([]), isEmpty);
    });

    test('excludes delivered sales', () {
      final sale = makeSale(
        shipmentStatus: ShipmentStatus.delivered,
        assembly: AssemblyStatus.inProgress,
        items: [
          makeSaleItem(
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent()],
          ),
        ],
      );
      expect(aggregateShoppingList([sale]), isEmpty);
    });

    test('excludes sales where all items are assembled', () {
      final sale = makeSale(
        assembly: AssemblyStatus.ready,
        items: [
          makeSaleItem(
            assembly: AssemblyStatus.ready,
            components: [makeComponent()],
          ),
        ],
      );
      expect(aggregateShoppingList([sale]), isEmpty);
    });

    test('excludes ready SaleItems within an otherwise open sale', () {
      final sale = makeSale(
        items: [
          makeSaleItem(
            id: 'item-1',
            assembly: AssemblyStatus.ready,
            components: [makeComponent(name: 'silver chain')],
          ),
          makeSaleItem(
            id: 'item-2',
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'blue bead')],
          ),
        ],
      );
      final result = aggregateShoppingList([sale]);
      expect(result, hasLength(1));
      expect(result.first.name, 'blue bead');
    });

    test('excludes already-acquired components', () {
      final sale = makeSale(
        assembly: AssemblyStatus.inProgress,
        items: [
          makeSaleItem(
            assembly: AssemblyStatus.inProgress,
            components: [
              makeComponent(name: 'silver chain', isAvailable: true),
              makeComponent(id: 'c2', name: 'blue bead', isAvailable: false),
            ],
          ),
        ],
      );
      final result = aggregateShoppingList([sale]);
      expect(result, hasLength(1));
      expect(result.first.name, 'blue bead');
    });

    test('merges same-named components across SaleItems and sums quantities', () {
      final sale = makeSale(
        items: [
          makeSaleItem(
            id: 'item-1',
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'blue bead', quantity: 3)],
          ),
          makeSaleItem(
            id: 'item-2',
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'blue bead', quantity: 2)],
          ),
        ],
      );
      final result = aggregateShoppingList([sale]);
      expect(result, hasLength(1));
      expect(result.first.name, 'blue bead');
      expect(result.first.totalQuantity, 5);
      expect(result.first.sources, hasLength(2));
    });

    test('merges case-insensitively', () {
      final sale = makeSale(
        items: [
          makeSaleItem(
            id: 'item-1',
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'Blue Bead', quantity: 2)],
          ),
          makeSaleItem(
            id: 'item-2',
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'blue bead', quantity: 3)],
          ),
        ],
      );
      final result = aggregateShoppingList([sale]);
      expect(result, hasLength(1));
      expect(result.first.totalQuantity, 5);
    });

    test('does not merge components with different names', () {
      final sale = makeSale(
        items: [
          makeSaleItem(
            id: 'item-1',
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'blue bead (45mm)', quantity: 2)],
          ),
          makeSaleItem(
            id: 'item-2',
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'blue bead', quantity: 3)],
          ),
        ],
      );
      final result = aggregateShoppingList([sale]);
      expect(result, hasLength(2));
    });

    test('merges same-named components across different Sales', () {
      final sale1 = makeSale(
        items: [
          makeSaleItem(
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'silver chain', quantity: 1)],
          ),
        ],
      );
      final sale2 = makeSale(
        items: [
          makeSaleItem(
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'silver chain', quantity: 2)],
          ),
        ],
      );
      final result = aggregateShoppingList([sale1, sale2]);
      expect(result, hasLength(1));
      expect(result.first.totalQuantity, 3);
      expect(result.first.sources, hasLength(2));
    });

    test('sorts by worst-case urgency: overdue before thisWeek before none', () {
      // Pin clock to Wednesday 2026-06-04; week = Mon 2026-06-01 – Sun 2026-06-07.
      final now = DateTime(2026, 6, 4);
      final overdueDate = DateTime(2026, 5, 1);
      final thisWeekDate = DateTime(2026, 6, 5);

      final overdueComp = makeComponent(id: 'c1', name: 'urgent bead');
      final thisWeekComp = makeComponent(id: 'c2', name: 'soon bead');
      final noUrgencyComp = makeComponent(id: 'c3', name: 'relaxed bead');

      Sale makeSaleWith(ComponentItem c, DateTime? scheduled) => Sale(
            id: c.id,
            buyerId: 'b1',
            buyerName: 'Test',
            items: [
              makeSaleItem(
                assembly: AssemblyStatus.inProgress,
                components: [c],
              ),
            ],
            payment:
                const SalePayment(status: PaymentStatus.paid, method: PaymentMethod.mbWay),
            shipment: const SaleShipment(
                type: DeliveryType.shipping, status: ShipmentStatus.pending),
            requiresNif: false,
            createdAt: DateTime(2026, 1, 1),
            scheduledDate: scheduled,
          );

      final result = aggregateShoppingList([
        makeSaleWith(noUrgencyComp, null),
        makeSaleWith(thisWeekComp, thisWeekDate),
        makeSaleWith(overdueComp, overdueDate),
      ], now: now);

      // Confirm urgency is computed correctly for this date (not tested here,
      // but the sort order depends on it).
      expect(result.map((a) => a.name).toList(),
          ['urgent bead', 'soon bead', 'relaxed bead']);
    });

    test('worst urgency of merged row is the highest across its sources', () {
      final overdueDate = DateTime(2026, 5, 1);

      final saleOverdue = Sale(
        id: 's1',
        buyerId: 'b1',
        buyerName: 'Ana',
        items: [
          makeSaleItem(
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'blue bead', quantity: 2)],
          ),
        ],
        payment: const SalePayment(status: PaymentStatus.paid, method: PaymentMethod.mbWay),
        shipment: const SaleShipment(
            type: DeliveryType.shipping, status: ShipmentStatus.pending),
        requiresNif: false,
        createdAt: DateTime(2026, 1, 1),
        scheduledDate: overdueDate,
      );
      final saleNoUrgency = makeSale(
        items: [
          makeSaleItem(
            assembly: AssemblyStatus.inProgress,
            components: [makeComponent(name: 'blue bead', quantity: 3)],
          ),
        ],
      );

      final result = aggregateShoppingList([saleNoUrgency, saleOverdue]);
      expect(result, hasLength(1));
      expect(result.first.worstUrgency, UrgencyLevel.overdue);
      expect(result.first.totalQuantity, 5);
    });
  });
}
