import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/models/sale_filter.dart';
import 'package:latitude_tracker/features/sales/services/sales_analytics_service.dart';

enum DashboardPeriod { yearly, monthly, weekly }

class DashboardPeriodStats {
  const DashboardPeriodStats({
    required this.paidRevenue,
    required this.paidCount,
  });

  factory DashboardPeriodStats.compute(
    List<Sale> all,
    DateTime start,
    DateTime end,
  ) {
    final paid = SalesAnalyticsService.computePeriodStats(all, start, end);
    return DashboardPeriodStats(
      paidRevenue: paid.revenue,
      paidCount: paid.count,
    );
  }

  final double paidRevenue;
  final int paidCount;
}

class DashboardActionCounts {
  const DashboardActionCounts({
    required this.unpaidActionCount,
    required this.unpaidActionRevenue,
    required this.pendingShipmentCount,
    required this.shippedCount,
    required this.assemblyNotReadyCount,
    required this.nifRequiredCount,
    required this.overdueCount,
    required this.upcomingCount,
  });

  factory DashboardActionCounts.compute(
    List<Sale> all, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    bool active(Sale s) => s.shipment.status != ShipmentStatus.delivered;

    var unpaidActionCount = 0;
    double unpaidActionRevenue = 0;
    var pendingShipmentCount = 0;
    var shippedCount = 0;
    var assemblyNotReadyCount = 0;
    var nifRequiredCount = 0;
    var overdueCount = 0;
    var upcomingCount = 0;

    for (final s in all) {
      if (s.payment.status == PaymentStatus.unpaid) {
        unpaidActionCount++;
        unpaidActionRevenue += s.totalPrice;
      }
      if (SaleFilter.pendingShipment.test(s)) pendingShipmentCount++;
      if (SaleFilter.shipped.test(s)) shippedCount++;
      if (SaleFilter.assemblyNotReady.test(s) && active(s)) {
        assemblyNotReadyCount++;
      }
      if (SaleFilter.nifRequired.test(s) && active(s) && !s.atSubmissionDone) {
        nifRequiredCount++;
      }
      if (SaleFilter.overdue.test(s, now: effectiveNow)) overdueCount++;
      if (SaleFilter.upcomingScheduled.test(s, now: effectiveNow)) {
        upcomingCount++;
      }
    }

    return DashboardActionCounts(
      unpaidActionCount: unpaidActionCount,
      unpaidActionRevenue: unpaidActionRevenue,
      pendingShipmentCount: pendingShipmentCount,
      shippedCount: shippedCount,
      assemblyNotReadyCount: assemblyNotReadyCount,
      nifRequiredCount: nifRequiredCount,
      overdueCount: overdueCount,
      upcomingCount: upcomingCount,
    );
  }

  final int unpaidActionCount;
  final double unpaidActionRevenue;
  final int pendingShipmentCount;
  final int shippedCount;
  final int assemblyNotReadyCount;
  final int nifRequiredCount;
  final int overdueCount;
  final int upcomingCount;
}
