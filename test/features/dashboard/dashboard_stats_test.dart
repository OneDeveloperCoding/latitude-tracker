import 'package:latitude_tracker/features/dashboard/models/dashboard_stats.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:test/test.dart';

import '../../helpers/sale_factory.dart';

void main() {
  group('DashboardActionCounts.compute', () {
    final now = DateTime(2026, 6, 4);

    test('shippedCount counts sales with shipped status', () {
      final sales = [
        makeSale(shipmentStatus: ShipmentStatus.shipped),
        makeSale(shipmentStatus: ShipmentStatus.shipped),
        makeSale(),
        makeSale(shipmentStatus: ShipmentStatus.delivered),
      ];

      final counts = DashboardActionCounts.compute(sales);

      expect(counts.shippedCount, 2);
    });

    test('upcomingCount counts sales with a future scheduled date', () {
      final sales = [
        makeSale(scheduledDate: DateTime(2026, 7)),
        makeSale(
          scheduledDate: DateTime(2026, 6, 4),
        ), // today — counts as upcoming
        makeSale(
          scheduledDate: DateTime(2026, 6, 3),
        ), // yesterday — overdue, not upcoming
        makeSale(), // no date
      ];

      final counts = DashboardActionCounts.compute(sales, now: now);

      expect(counts.upcomingCount, 2);
    });

    test('upcomingCount excludes delivered sales', () {
      final sales = [
        makeSale(
          scheduledDate: DateTime(2026, 7),
          shipmentStatus: ShipmentStatus.delivered,
        ),
        makeSale(scheduledDate: DateTime(2026, 7)),
      ];

      final counts = DashboardActionCounts.compute(sales, now: now);

      expect(counts.upcomingCount, 1);
    });

    group('needsMaterialsCount and readyToAssembleCount', () {
      final missingComponent = ComponentItem(
        id: 'c1',
        name: 'Silver chain',
        quantity: 1,
        isAvailable: false,
      );
      final availableComponent = ComponentItem(
        id: 'c2',
        name: 'Silver chain',
        quantity: 1,
        isAvailable: true,
      );

      test('counts a sale that has at least one unacquired component', () {
        final sales = [
          makeSale(
            items: [makeSaleItem(components: [missingComponent])],
          ),
        ];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.needsMaterialsCount, 1);
      });

      test('does not count a sale with no components even if assembly is notStarted', () {
        final sales = [
          makeSale(assembly: AssemblyStatus.notStarted),
        ];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.needsMaterialsCount, 0);
      });

      test('does not count a sale where all components are available', () {
        final sales = [
          makeSale(
            items: [makeSaleItem(components: [availableComponent])],
          ),
        ];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.needsMaterialsCount, 0);
      });

      test('does not count delivered sales', () {
        final sales = [
          makeSale(
            shipmentStatus: ShipmentStatus.delivered,
            items: [makeSaleItem(components: [missingComponent])],
          ),
        ];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.needsMaterialsCount, 0);
      });

      test('counts only sales with at least one missing component across multiple', () {
        final sales = [
          makeSale(items: [makeSaleItem(components: [missingComponent])]),
          makeSale(items: [makeSaleItem(components: [availableComponent])]),
          makeSale(assembly: AssemblyStatus.notStarted),
          makeSale(items: [makeSaleItem(components: [missingComponent])]),
        ];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.needsMaterialsCount, 2);
      });

      test('readyToAssemble counts a new sale with no components', () {
        final sales = [makeSale(assembly: AssemblyStatus.notStarted)];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.readyToAssembleCount, 1);
      });

      test('readyToAssemble counts a sale where all components are acquired', () {
        final sales = [
          makeSale(
            items: [
              makeSaleItem(
                assembly: AssemblyStatus.notStarted,
                components: [availableComponent],
              ),
            ],
          ),
        ];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.readyToAssembleCount, 1);
      });

      test('readyToAssemble does not count a sale with missing components', () {
        final sales = [
          makeSale(items: [makeSaleItem(components: [missingComponent])]),
        ];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.readyToAssembleCount, 0);
      });

      test('readyToAssemble does not count delivered sales', () {
        final sales = [
          makeSale(
            assembly: AssemblyStatus.notStarted,
            shipmentStatus: ShipmentStatus.delivered,
          ),
        ];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.readyToAssembleCount, 0);
      });

      test('readyToAssemble does not count assembly-complete sales', () {
        final sales = [makeSale(assembly: AssemblyStatus.ready)];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.readyToAssembleCount, 0);
      });

      test('needsMaterials and readyToAssemble are mutually exclusive', () {
        final sales = [
          makeSale(items: [makeSaleItem(components: [missingComponent])]),
          makeSale(assembly: AssemblyStatus.notStarted),
        ];

        final counts = DashboardActionCounts.compute(sales);

        expect(counts.needsMaterialsCount, 1);
        expect(counts.readyToAssembleCount, 1);
      });
    });
  });
}
