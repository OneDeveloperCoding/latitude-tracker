import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/models/sale_filter.dart';
import 'package:latitude_tracker/features/sales/services/sales_analytics_service.dart';

enum DashboardPeriod { yearly, monthly, weekly }

class DashboardStats {

  const DashboardStats({
    required this.paidRevenue,
    required this.unpaidRevenue,
    required this.paidCount,
    required this.unpaidCount,
    required this.unpaidActionCount,
    required this.unpaidActionRevenue,
    required this.pendingShipmentCount,
    required this.shippedCount,
    required this.assemblyNotReadyCount,
    required this.nifRequiredCount,
    required this.overdueCount,
    required this.upcomingCount,
  });

  factory DashboardStats.compute(
    List<Sale> all,
    DateTime start,
    DateTime end, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    bool active(Sale s) => s.shipment.status != ShipmentStatus.delivered;

    // Period-scoped revenue — delegate to the single canonical implementation.
    final paid = SalesAnalyticsService.computePeriodStats(all, start, end);
    double unpaidRevenue = 0;
    var unpaidCount = 0;
    for (final s in all) {
      if (!s.inPeriod(start, end)) continue;
      if (s.payment.status != PaymentStatus.unpaid) continue;
      unpaidRevenue += s.totalPrice;
      unpaidCount++;
    }

    var unpaidActionCount = 0;
    double unpaidActionRevenue = 0;
    var pendingShipmentCount = 0;
    var shippedCount = 0;
    var assemblyNotReadyCount = 0;
    var nifRequiredCount = 0;
    var overdueCount = 0;
    var upcomingCount = 0;

    for (final s in all) {
      // Global action counts — always current, period-independent.
      if (s.payment.status == PaymentStatus.unpaid) {
        unpaidActionCount++;
        unpaidActionRevenue += s.totalPrice;
      }
      if (SaleFilter.pendingShipment.test(s)) pendingShipmentCount++;
      if (SaleFilter.shipped.test(s)) shippedCount++;
      if (SaleFilter.assemblyNotReady.test(s) && active(s)) assemblyNotReadyCount++;
      if (SaleFilter.nifRequired.test(s) && active(s) && !s.atSubmissionDone) nifRequiredCount++;
      if (SaleFilter.overdue.test(s, now: effectiveNow)) overdueCount++;
      if (SaleFilter.upcomingScheduled.test(s, now: effectiveNow)) upcomingCount++;
    }

    return DashboardStats(
      paidRevenue: paid.revenue,
      unpaidRevenue: unpaidRevenue,
      paidCount: paid.count,
      unpaidCount: unpaidCount,
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
  // Period-scoped: reflect sales created within the selected period.
  final double paidRevenue;
  final double unpaidRevenue;
  final int paidCount;
  final int unpaidCount;

  // Global: current action state regardless of which period is selected.
  // These must match what the destination screens show so counts stay consistent.
  final int unpaidActionCount;
  final double unpaidActionRevenue;
  final int pendingShipmentCount;
  final int shippedCount;
  final int assemblyNotReadyCount;
  final int nifRequiredCount;
  final int overdueCount;
  final int upcomingCount;

  int get totalCount => paidCount + unpaidCount;
}
