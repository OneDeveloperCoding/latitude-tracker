import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/models/sale_filter.dart';

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
          SaleFilter.unpaid.test(makeSale(payment: PaymentStatus.paid)),
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
          SaleFilter.nifRequired.test(makeSale(requiresNif: false)),
          isFalse,
        );
      });
    });

    group('scheduled', () {
      test('passes when scheduledDate is set', () {
        expect(
          SaleFilter.scheduled.test(makeSale(scheduledDate: DateTime(2026, 7, 1))),
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
          SaleFilter.pendingShipment.test(makeSale(
            delivery: DeliveryType.shipping,
            shipmentStatus: ShipmentStatus.pending,
          )),
          isTrue,
        );
      });

      test('fails for pickup even if pending', () {
        expect(
          SaleFilter.pendingShipment.test(makeSale(
            delivery: DeliveryType.pickup,
            shipmentStatus: ShipmentStatus.pending,
          )),
          isFalse,
        );
      });

      test('fails for shipped status', () {
        expect(
          SaleFilter.pendingShipment.test(makeSale(
            delivery: DeliveryType.shipping,
            shipmentStatus: ShipmentStatus.shipped,
          )),
          isFalse,
        );
      });
    });

    group('shipped', () {
      test('passes for shipped status', () {
        expect(
          SaleFilter.shipped.test(makeSale(shipmentStatus: ShipmentStatus.shipped)),
          isTrue,
        );
      });

      test('fails for pending', () {
        expect(
          SaleFilter.shipped.test(makeSale(shipmentStatus: ShipmentStatus.pending)),
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
          SaleFilter.pickup.test(makeSale(delivery: DeliveryType.shipping)),
          isFalse,
        );
      });
    });

    group('assemblyNotReady', () {
      test('passes when assembly is notStarted', () {
        expect(
          SaleFilter.assemblyNotReady.test(
              makeSale(assembly: AssemblyStatus.notStarted)),
          isTrue,
        );
      });

      test('passes when assembly is waitingForMaterials', () {
        expect(
          SaleFilter.assemblyNotReady.test(
              makeSale(assembly: AssemblyStatus.waitingForMaterials)),
          isTrue,
        );
      });

      test('fails when assembly is ready', () {
        expect(
          SaleFilter.assemblyNotReady.test(
              makeSale(assembly: AssemblyStatus.ready)),
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
              shipmentStatus: ShipmentStatus.pending,
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
              scheduledDate: DateTime(2026, 6, 1),
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
  });
}
