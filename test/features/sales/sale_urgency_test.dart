import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency.dart';

import '../../helpers/sale_factory.dart';

// Reference: Thursday 2026-06-04
//   startOfThisWeek : Monday 2026-06-01
//   startOfNextWeek : Monday 2026-06-08
final _kNow = DateTime(2026, 6, 4);

void main() {
  group('SaleUrgency.urgencyLevel', () {
    test('none when no scheduled date', () {
      expect(makeSale().urgencyLevel(now: _kNow), UrgencyLevel.none);
    });

    test('none when delivered regardless of scheduled date', () {
      final sale = makeSale(
        scheduledDate: DateTime(2026, 5, 1),
        shipmentStatus: ShipmentStatus.delivered,
      );
      expect(sale.urgencyLevel(now: _kNow), UrgencyLevel.none);
    });

    test('overdue when scheduled before start of this week', () {
      final sale = makeSale(scheduledDate: DateTime(2026, 5, 31)); // before Mon Jun 1
      expect(sale.urgencyLevel(now: _kNow), UrgencyLevel.overdue);
    });

    test('thisWeek on Monday (first day of week)', () {
      final sale = makeSale(scheduledDate: DateTime(2026, 6, 1));
      expect(sale.urgencyLevel(now: _kNow), UrgencyLevel.thisWeek);
    });

    test('thisWeek on Sunday (last day of week)', () {
      final sale = makeSale(scheduledDate: DateTime(2026, 6, 7));
      expect(sale.urgencyLevel(now: _kNow), UrgencyLevel.thisWeek);
    });

    test('none when scheduled start of next week', () {
      final sale = makeSale(scheduledDate: DateTime(2026, 6, 8)); // Mon of next week
      expect(sale.urgencyLevel(now: _kNow), UrgencyLevel.none);
    });
  });

  group('SaleUrgency.urgencyReasons', () {
    test('empty when urgency level is none', () {
      final sale = makeSale(scheduledDate: DateTime(2026, 6, 9));
      expect(sale.urgencyReasons(now: _kNow), isEmpty);
    });

    test('waitingForMaterials reason — not assemblyNotReady', () {
      final sale = makeSale(
        scheduledDate: DateTime(2026, 6, 3),
        assembly: AssemblyStatus.waitingForMaterials,
      );
      final reasons = sale.urgencyReasons(now: _kNow);
      expect(reasons, contains(UrgencyReasonType.waitingForMaterials));
      expect(reasons, isNot(contains(UrgencyReasonType.assemblyNotReady)));
    });

    test('assemblyNotReady reason for notStarted', () {
      final sale = makeSale(
        scheduledDate: DateTime(2026, 6, 3),
        assembly: AssemblyStatus.notStarted,
      );
      expect(
        sale.urgencyReasons(now: _kNow),
        contains(UrgencyReasonType.assemblyNotReady),
      );
    });

    test('assemblyNotReady reason for inProgress', () {
      final sale = makeSale(
        scheduledDate: DateTime(2026, 6, 3),
        assembly: AssemblyStatus.inProgress,
      );
      expect(
        sale.urgencyReasons(now: _kNow),
        contains(UrgencyReasonType.assemblyNotReady),
      );
    });

    test('no assembly reason when ready', () {
      final sale = makeSale(
        scheduledDate: DateTime(2026, 6, 3),
        assembly: AssemblyStatus.ready,
      );
      final reasons = sale.urgencyReasons(now: _kNow);
      expect(reasons, isNot(contains(UrgencyReasonType.waitingForMaterials)));
      expect(reasons, isNot(contains(UrgencyReasonType.assemblyNotReady)));
    });

    test('paymentPending reason when unpaid', () {
      final sale = makeSale(
        scheduledDate: DateTime(2026, 6, 3),
        payment: PaymentStatus.unpaid,
      );
      expect(
        sale.urgencyReasons(now: _kNow),
        contains(UrgencyReasonType.paymentPending),
      );
    });

    test('no payment reason when paid', () {
      final sale = makeSale(
        scheduledDate: DateTime(2026, 6, 3),
        payment: PaymentStatus.paid,
      );
      expect(
        sale.urgencyReasons(now: _kNow),
        isNot(contains(UrgencyReasonType.paymentPending)),
      );
    });

    test('notYetShipped when overdue and shipment pending', () {
      final sale = makeSale(
        scheduledDate: DateTime(2026, 5, 31),
        shipmentStatus: ShipmentStatus.pending,
      );
      expect(
        sale.urgencyReasons(now: _kNow),
        contains(UrgencyReasonType.notYetShipped),
      );
    });

    test('no notYetShipped when thisWeek (not overdue)', () {
      final sale = makeSale(
        scheduledDate: DateTime(2026, 6, 3),
        shipmentStatus: ShipmentStatus.pending,
      );
      expect(
        sale.urgencyReasons(now: _kNow),
        isNot(contains(UrgencyReasonType.notYetShipped)),
      );
    });

    test('all three blockers accumulate when overdue', () {
      final sale = makeSale(
        scheduledDate: DateTime(2026, 5, 31),
        assembly: AssemblyStatus.notStarted,
        payment: PaymentStatus.unpaid,
        shipmentStatus: ShipmentStatus.pending,
      );
      final reasons = sale.urgencyReasons(now: _kNow);
      expect(reasons, containsAll([
        UrgencyReasonType.assemblyNotReady,
        UrgencyReasonType.paymentPending,
        UrgencyReasonType.notYetShipped,
      ]));
      expect(reasons, hasLength(3));
    });
  });

  group('SaleUrgency.daysUntilScheduled', () {
    test('null when no scheduled date', () {
      expect(makeSale().daysUntilScheduled(now: _kNow), isNull);
    });

    test('0 when scheduled today', () {
      final sale = makeSale(scheduledDate: DateTime(2026, 6, 4));
      expect(sale.daysUntilScheduled(now: _kNow), 0);
    });

    test('1 when scheduled tomorrow', () {
      final sale = makeSale(scheduledDate: DateTime(2026, 6, 5));
      expect(sale.daysUntilScheduled(now: _kNow), 1);
    });

    test('negative when scheduled in the past', () {
      final sale = makeSale(scheduledDate: DateTime(2026, 6, 2));
      expect(sale.daysUntilScheduled(now: _kNow), -2);
    });
  });

  group('SaleUrgency.daysOpen', () {
    test('0 when created today', () {
      final sale = makeSale(createdAt: DateTime(2026, 6, 4));
      expect(sale.daysOpen(now: _kNow), 0);
    });

    test('1 when created yesterday', () {
      final sale = makeSale(createdAt: DateTime(2026, 6, 3));
      expect(sale.daysOpen(now: _kNow), 1);
    });

    test('counts full days since creation', () {
      final sale = makeSale(createdAt: DateTime(2026, 5, 1));
      expect(sale.daysOpen(now: _kNow), 34);
    });
  });
}
