import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sale_grouper.dart';
import 'package:test/test.dart';

import '../../helpers/sale_factory.dart';

// Reference: Thursday 2026-06-04 (weekday = 4)
//   startOfThisWeek = 2026-06-01 (Monday)
//   startOfNextWeek = 2026-06-08
//   endOfNextWeek   = 2026-06-15
final _kNow = DateTime(2026, 6, 4);

void main() {
  group('SaleGrouper.byWeek — bucket assignment', () {
    Sale saleWithScheduled(DateTime date,
            {ShipmentStatus shipment = ShipmentStatus.pending}) =>
        makeSale(scheduledDate: date, shipmentStatus: shipment);

    Sale saleWithCreatedAt(DateTime date) =>
        makeSale(createdAt: date);

    test('past scheduledDate + pending shipment → Overdue', () {
      final sale = saleWithScheduled(DateTime(2026, 5, 31));
      final groups = SaleGrouper.byWeek([sale], now: _kNow);
      expect(groups.keys.first, 'Overdue');
    });

    test('past scheduledDate + delivered shipment → not Overdue (month bucket)', () {
      final sale =
          saleWithScheduled(DateTime(2026, 5, 31), shipment: ShipmentStatus.delivered);
      final groups = SaleGrouper.byWeek([sale], now: _kNow);
      expect(groups.containsKey('Overdue'), isFalse);
      expect(groups.keys.first, 'May 2026');
    });

    test('scheduledDate exactly at startOfThisWeek → This week', () {
      final sale = saleWithScheduled(DateTime(2026, 6));
      final groups = SaleGrouper.byWeek([sale], now: _kNow);
      expect(groups.keys.first, 'This week');
    });

    test('scheduledDate within this week → This week', () {
      final sale = saleWithScheduled(DateTime(2026, 6, 4));
      final groups = SaleGrouper.byWeek([sale], now: _kNow);
      expect(groups.keys.first, 'This week');
    });

    test('scheduledDate on last day of this week → This week', () {
      final sale = saleWithScheduled(DateTime(2026, 6, 7));
      final groups = SaleGrouper.byWeek([sale], now: _kNow);
      expect(groups.keys.first, 'This week');
    });

    test('scheduledDate exactly at startOfNextWeek → Next week', () {
      final sale = saleWithScheduled(DateTime(2026, 6, 8));
      final groups = SaleGrouper.byWeek([sale], now: _kNow);
      expect(groups.keys.first, 'Next week');
    });

    test('scheduledDate within next week → Next week', () {
      final sale = saleWithScheduled(DateTime(2026, 6, 14));
      final groups = SaleGrouper.byWeek([sale], now: _kNow);
      expect(groups.keys.first, 'Next week');
    });

    test('scheduledDate after endOfNextWeek → Later', () {
      final sale = saleWithScheduled(DateTime(2026, 6, 16));
      final groups = SaleGrouper.byWeek([sale], now: _kNow);
      expect(groups.keys.first, 'Later');
    });

    test('no scheduledDate, old createdAt → month bucket', () {
      final sale = saleWithCreatedAt(DateTime(2026, 1, 15));
      final groups = SaleGrouper.byWeek([sale], now: _kNow);
      expect(groups.keys.first, 'January 2026');
    });

    test('no scheduledDate, createdAt in this week → This week', () {
      final sale = saleWithCreatedAt(DateTime(2026, 6, 3));
      final groups = SaleGrouper.byWeek([sale], now: _kNow);
      expect(groups.keys.first, 'This week');
    });
  });

  group('SaleGrouper.byWeek — bucket ordering', () {
    test('fixed buckets appear before month buckets', () {
      final sales = [
        makeSale(createdAt: DateTime(2026, 3)),   // month bucket
        makeSale(scheduledDate: DateTime(2026, 6, 8)), // Next week
        makeSale(scheduledDate: DateTime(2026, 5)), // Overdue
        makeSale(scheduledDate: DateTime(2026, 6, 4)), // This week
        makeSale(scheduledDate: DateTime(2026, 6, 20)), // Later
      ];
      final keys = SaleGrouper.byWeek(sales, now: _kNow).keys.toList();
      expect(keys[0], 'Overdue');
      expect(keys[1], 'This week');
      expect(keys[2], 'Next week');
      expect(keys[3], 'Later');
      expect(keys[4], 'March 2026');
    });

    test('empty list returns empty map', () {
      expect(SaleGrouper.byWeek([], now: _kNow), isEmpty);
    });
  });

  group('SaleGrouper.byWeek — multiple sales in same bucket', () {
    test('two sales in the same week land in the same bucket', () {
      final sales = [
        makeSale(scheduledDate: DateTime(2026, 6, 2)),
        makeSale(scheduledDate: DateTime(2026, 6, 5)),
      ];
      final groups = SaleGrouper.byWeek(sales, now: _kNow);
      expect(groups.length, 1);
      expect(groups['This week']!.length, 2);
    });
  });

  group('SaleGrouper.byCreatedMonth', () {
    test('groups by month label and sorts newest first', () {
      final sales = [
        makeSale(createdAt: DateTime(2026, 1, 5)),
        makeSale(createdAt: DateTime(2026, 3, 10)),
        makeSale(createdAt: DateTime(2026, 1, 20)),
      ];
      final groups = SaleGrouper.byCreatedMonth(sales);
      final keys = groups.keys.toList();
      expect(keys.first, 'March 2026');
      expect(groups['January 2026']!.length, 2);
    });
  });
}
