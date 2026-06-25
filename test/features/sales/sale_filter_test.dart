import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/models/sale_filter.dart';
import 'package:test/test.dart';

import '../../helpers/sale_factory.dart';

// Reference date used for overdue boundary checks.
final _kNow = DateTime(2026, 6, 4);

void main() {
  group('SaleFilter', () {
    test('all always passes', () {
      expect(SaleFilter.all.test(makeSale(), now: _kNow), isTrue);
    });

    group('unpaid', () {
      test('passes for unpaid sale', () {
        expect(
          SaleFilter.unpaid.test(makeSale(payment: PaymentStatus.unpaid)),
          isTrue,
        );
      });

      test('fails for paid sale', () {
        expect(
          SaleFilter.unpaid.test(makeSale()),
          isFalse,
        );
      });
    });

    group('nifRequired', () {
      test('passes when requiresNif is true', () {
        expect(
          SaleFilter.nifRequired.test(makeSale(requiresNif: true)),
          isTrue,
        );
      });

      test('fails when requiresNif is false', () {
        expect(
          SaleFilter.nifRequired.test(makeSale()),
          isFalse,
        );
      });
    });

    group('scheduled', () {
      test('passes when scheduledDate is set', () {
        expect(
          SaleFilter.scheduled.test(makeSale(scheduledDate: DateTime(2026, 7))),
          isTrue,
        );
      });

      test('fails when no scheduledDate', () {
        expect(SaleFilter.scheduled.test(makeSale()), isFalse);
      });
    });

    group('pendingShipment', () {
      test('passes for shipping + pending', () {
        expect(
          SaleFilter.pendingShipment.test(makeSale()),
          isTrue,
        );
      });

      test('passes for handDelivery + pending', () {
        expect(
          SaleFilter.pendingShipment.test(
            makeSale(
              delivery: DeliveryType.handDelivery,
            ),
          ),
          isTrue,
        );
      });

      test('fails for pickup even if pending', () {
        expect(
          SaleFilter.pendingShipment.test(
            makeSale(
              delivery: DeliveryType.pickup,
            ),
          ),
          isFalse,
        );
      });

      test('fails for shipped status', () {
        expect(
          SaleFilter.pendingShipment.test(
            makeSale(
              shipmentStatus: ShipmentStatus.shipped,
            ),
          ),
          isFalse,
        );
      });
    });

    group('shipped', () {
      test('passes for shipped status', () {
        expect(
          SaleFilter.shipped.test(
            makeSale(shipmentStatus: ShipmentStatus.shipped),
          ),
          isTrue,
        );
      });

      test('fails for pending', () {
        expect(
          SaleFilter.shipped.test(makeSale()),
          isFalse,
        );
      });
    });

    group('pickup', () {
      test('passes for pickup delivery type', () {
        expect(
          SaleFilter.pickup.test(makeSale(delivery: DeliveryType.pickup)),
          isTrue,
        );
      });

      test('fails for shipping delivery type', () {
        expect(
          SaleFilter.pickup.test(makeSale()),
          isFalse,
        );
      });
    });

    group('handDelivery', () {
      test('passes for handDelivery type', () {
        expect(
          SaleFilter.handDelivery.test(
            makeSale(delivery: DeliveryType.handDelivery),
          ),
          isTrue,
        );
      });

      test('fails for shipping type', () {
        expect(
          SaleFilter.handDelivery.test(makeSale()),
          isFalse,
        );
      });

      test('fails for pickup type', () {
        expect(
          SaleFilter.handDelivery.test(makeSale(delivery: DeliveryType.pickup)),
          isFalse,
        );
      });
    });

    group('assemblyNotReady', () {
      test('passes when assembly is notStarted', () {
        expect(
          SaleFilter.assemblyNotReady.test(
            makeSale(assembly: AssemblyStatus.notStarted),
          ),
          isTrue,
        );
      });

      test('passes when assembly is waitingForMaterials', () {
        expect(
          SaleFilter.assemblyNotReady.test(
            makeSale(assembly: AssemblyStatus.waitingForMaterials),
          ),
          isTrue,
        );
      });

      test('fails when assembly is ready', () {
        expect(
          SaleFilter.assemblyNotReady.test(makeSale()),
          isFalse,
        );
      });
    });

    group('readyToAssemble', () {
      const availableComponent = ComponentItem(
        id: 'c1',
        name: 'Silver chain',
        isAvailable: true,
      );
      const missingComponent = ComponentItem(
        id: 'c2',
        name: 'Silver chain',
        isAvailable: false,
      );

      test('passes when notStarted with no components', () {
        expect(
          SaleFilter.readyToAssemble.test(
            makeSale(assembly: AssemblyStatus.notStarted),
          ),
          isTrue,
        );
      });

      test('passes when notStarted with all components available', () {
        expect(
          SaleFilter.readyToAssemble.test(
            makeSale(
              items: [
                makeSaleItem(
                  assembly: AssemblyStatus.notStarted,
                  components: [availableComponent],
                ),
              ],
            ),
          ),
          isTrue,
        );
      });

      test('fails when inProgress — already being assembled', () {
        expect(
          SaleFilter.readyToAssemble.test(
            makeSale(assembly: AssemblyStatus.inProgress),
          ),
          isFalse,
        );
      });

      test('fails when assembly is ready', () {
        expect(
          SaleFilter.readyToAssemble.test(makeSale()),
          isFalse,
        );
      });

      test('fails when delivered', () {
        expect(
          SaleFilter.readyToAssemble.test(
            makeSale(
              assembly: AssemblyStatus.notStarted,
              shipmentStatus: ShipmentStatus.delivered,
            ),
          ),
          isFalse,
        );
      });

      test('fails when a component is missing', () {
        expect(
          SaleFilter.readyToAssemble.test(
            makeSale(
              items: [
                makeSaleItem(
                  assembly: AssemblyStatus.notStarted,
                  components: [missingComponent],
                ),
              ],
            ),
          ),
          isFalse,
        );
      });
    });

    group('overdue', () {
      test('passes when scheduled yesterday and not delivered', () {
        expect(
          SaleFilter.overdue.test(
            makeSale(
              scheduledDate: DateTime(2026, 6, 3),
            ),
            now: _kNow,
          ),
          isTrue,
        );
      });

      test('fails when scheduled today (not yet overdue)', () {
        expect(
          SaleFilter.overdue.test(
            makeSale(scheduledDate: DateTime(2026, 6, 4)),
            now: _kNow,
          ),
          isFalse,
        );
      });

      test('fails when scheduled in the past but delivered', () {
        expect(
          SaleFilter.overdue.test(
            makeSale(
              scheduledDate: DateTime(2026, 6),
              shipmentStatus: ShipmentStatus.delivered,
            ),
            now: _kNow,
          ),
          isFalse,
        );
      });

      test('fails when no scheduled date', () {
        expect(SaleFilter.overdue.test(makeSale(), now: _kNow), isFalse);
      });
    });

    group('upcomingScheduled', () {
      test('passes when scheduled today and not delivered', () {
        expect(
          SaleFilter.upcomingScheduled.test(
            makeSale(
              scheduledDate: DateTime(2026, 6, 4),
            ),
            now: _kNow,
          ),
          isTrue,
        );
      });

      test('passes when scheduled in the future and not delivered', () {
        expect(
          SaleFilter.upcomingScheduled.test(
            makeSale(
              scheduledDate: DateTime(2026, 7),
            ),
            now: _kNow,
          ),
          isTrue,
        );
      });

      test('fails when scheduled in the past (overdue)', () {
        expect(
          SaleFilter.upcomingScheduled.test(
            makeSale(
              scheduledDate: DateTime(2026, 6, 3),
            ),
            now: _kNow,
          ),
          isFalse,
        );
      });

      test('fails when no scheduled date', () {
        expect(
          SaleFilter.upcomingScheduled.test(makeSale(), now: _kNow),
          isFalse,
        );
      });

      test('fails when scheduled in the future but already delivered', () {
        expect(
          SaleFilter.upcomingScheduled.test(
            makeSale(
              scheduledDate: DateTime(2026, 7),
              shipmentStatus: ShipmentStatus.delivered,
            ),
            now: _kNow,
          ),
          isFalse,
        );
      });
    });
  });

  group('testSaleFilters', () {
    test('empty filter set passes all sales', () {
      expect(testSaleFilters(makeSale(), {}), isTrue);
    });

    test('single filter matches when test passes', () {
      expect(
        testSaleFilters(
          makeSale(payment: PaymentStatus.unpaid),
          {SaleFilter.unpaid},
        ),
        isTrue,
      );
    });

    test('single filter rejects when test fails', () {
      expect(
        testSaleFilters(
          makeSale(),
          {SaleFilter.unpaid},
        ),
        isFalse,
      );
    });

    test('AND logic — both filters must pass', () {
      final sale = makeSale(
        payment: PaymentStatus.unpaid,
        requiresNif: true,
      );
      expect(
        testSaleFilters(sale, {SaleFilter.unpaid, SaleFilter.nifRequired}),
        isTrue,
      );
    });

    test('AND logic — fails when only one filter passes', () {
      final sale = makeSale(
        requiresNif: true,
      );
      expect(
        testSaleFilters(sale, {SaleFilter.unpaid, SaleFilter.nifRequired}),
        isFalse,
      );
    });

    group('dateFrom', () {
      test('passes when sale is on dateFrom', () {
        final sale = makeSale(createdAt: DateTime(2026, 6));
        expect(
          testSaleFilters(sale, {}, dateFrom: DateTime(2026, 6)),
          isTrue,
        );
      });

      test('passes when sale is after dateFrom', () {
        final sale = makeSale(createdAt: DateTime(2026, 6, 10));
        expect(
          testSaleFilters(sale, {}, dateFrom: DateTime(2026, 6)),
          isTrue,
        );
      });

      test('fails when sale is before dateFrom', () {
        final sale = makeSale(createdAt: DateTime(2026, 5, 31));
        expect(
          testSaleFilters(sale, {}, dateFrom: DateTime(2026, 6)),
          isFalse,
        );
      });
    });

    group('dateTo', () {
      test('passes when sale is on dateTo', () {
        final sale = makeSale(createdAt: DateTime(2026, 6, 30));
        expect(
          testSaleFilters(sale, {}, dateTo: DateTime(2026, 6, 30)),
          isTrue,
        );
      });

      test('fails when sale is after dateTo', () {
        final sale = makeSale(createdAt: DateTime(2026, 7));
        expect(
          testSaleFilters(sale, {}, dateTo: DateTime(2026, 6, 30)),
          isFalse,
        );
      });
    });

    test('date range + filter — AND of both constraints', () {
      final sale = makeSale(
        payment: PaymentStatus.unpaid,
        createdAt: DateTime(2026, 6, 15),
      );
      expect(
        testSaleFilters(
          sale,
          {SaleFilter.unpaid},
          dateFrom: DateTime(2026, 6),
          dateTo: DateTime(2026, 6, 30),
        ),
        isTrue,
      );
    });

    test('date range + filter — fails when sale is outside range', () {
      final sale = makeSale(
        payment: PaymentStatus.unpaid,
        createdAt: DateTime(2026, 7),
      );
      expect(
        testSaleFilters(
          sale,
          {SaleFilter.unpaid},
          dateFrom: DateTime(2026, 6),
          dateTo: DateTime(2026, 6, 30),
        ),
        isFalse,
      );
    });
  });
}
