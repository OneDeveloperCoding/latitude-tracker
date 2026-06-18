import 'package:latitude_tracker/features/dashboard/models/dashboard_stats.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:test/test.dart';

import '../../helpers/sale_factory.dart';

void main() {
  final jan = DateTime(2026);
  final feb = DateTime(2026, 2);

  group('DashboardStats.compute action counts', () {
    final now = DateTime(2026, 6, 4);

    test('shippedCount counts sales with shipped status', () {
      final sales = [
        makeSale(shipmentStatus: ShipmentStatus.shipped),
        makeSale(shipmentStatus: ShipmentStatus.shipped),
        makeSale(),
        makeSale(shipmentStatus: ShipmentStatus.delivered),
      ];

      final stats = DashboardStats.compute(sales, jan, feb);

      expect(stats.shippedCount, 2);
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

      final stats = DashboardStats.compute(sales, jan, feb, now: now);

      expect(stats.upcomingCount, 2);
    });

    test('upcomingCount excludes delivered sales', () {
      final sales = [
        makeSale(
          scheduledDate: DateTime(2026, 7),
          shipmentStatus: ShipmentStatus.delivered,
        ),
        makeSale(scheduledDate: DateTime(2026, 7)),
      ];

      final stats = DashboardStats.compute(sales, jan, feb, now: now);

      expect(stats.upcomingCount, 1);
    });
  });
}
