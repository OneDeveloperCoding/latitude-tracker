import '../../sales/models/sale.dart';
import '../../sales/models/sale_filter.dart';

class DashboardStats {
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
  final int assemblyNotReadyCount;
  final int nifRequiredCount;
  final int overdueCount;

  int get totalCount => paidCount + unpaidCount;
  double get avgOrderValue => paidCount > 0 ? paidRevenue / paidCount : 0;

  const DashboardStats({
    required this.paidRevenue,
    required this.unpaidRevenue,
    required this.paidCount,
    required this.unpaidCount,
    required this.unpaidActionCount,
    required this.unpaidActionRevenue,
    required this.pendingShipmentCount,
    required this.assemblyNotReadyCount,
    required this.nifRequiredCount,
    required this.overdueCount,
  });

  factory DashboardStats.compute(
    List<Sale> all,
    DateTime start,
    DateTime end,
  ) {
    final now = DateTime.now();
    bool active(Sale s) => s.shipment.status != ShipmentStatus.delivered;

    double paidRevenue = 0;
    double unpaidRevenue = 0;
    int paidCount = 0;
    int unpaidCount = 0;
    int unpaidActionCount = 0;
    double unpaidActionRevenue = 0;
    int pendingShipmentCount = 0;
    int assemblyNotReadyCount = 0;
    int nifRequiredCount = 0;
    int overdueCount = 0;

    for (final s in all) {
      // Global action counts — always current, period-independent.
      if (s.payment.status == PaymentStatus.unpaid) {
        unpaidActionCount++;
        unpaidActionRevenue += s.price;
      }
      if (SaleFilter.pendingShipment.test(s)) pendingShipmentCount++;
      if (SaleFilter.assemblyNotReady.test(s) && active(s)) assemblyNotReadyCount++;
      if (SaleFilter.nifRequired.test(s) && active(s) && !s.atSubmissionDone) nifRequiredCount++;
      if (SaleFilter.overdue.test(s, now: now)) overdueCount++;

      // Period-scoped revenue — only sales created within the selected window.
      if (s.createdAt.isBefore(start) || !s.createdAt.isBefore(end)) continue;
      if (s.payment.status == PaymentStatus.paid) {
        paidRevenue += s.price;
        paidCount++;
      } else {
        unpaidRevenue += s.price;
        unpaidCount++;
      }
    }

    return DashboardStats(
      paidRevenue: paidRevenue,
      unpaidRevenue: unpaidRevenue,
      paidCount: paidCount,
      unpaidCount: unpaidCount,
      unpaidActionCount: unpaidActionCount,
      unpaidActionRevenue: unpaidActionRevenue,
      pendingShipmentCount: pendingShipmentCount,
      assemblyNotReadyCount: assemblyNotReadyCount,
      nifRequiredCount: nifRequiredCount,
      overdueCount: overdueCount,
    );
  }
}
