import '../../sales/models/sale.dart';
import '../../sales/models/sale_filter.dart';

class DashboardStats {
  final double paidRevenue;
  final double unpaidRevenue;
  final int paidCount;
  final int unpaidCount;
  final int pendingShipmentCount;
  final int assemblyNotReadyCount;
  final int nifRequiredCount;
  final int overdueCount;

  const DashboardStats({
    required this.paidRevenue,
    required this.unpaidRevenue,
    required this.paidCount,
    required this.unpaidCount,
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

    // Action counts exclude already-delivered sales — those need no further action.
    bool active(Sale s) => s.shipment.status != ShipmentStatus.delivered;

    double paidRevenue = 0;
    double unpaidRevenue = 0;
    int paidCount = 0;
    int unpaidCount = 0;
    int pendingShipmentCount = 0;
    int assemblyNotReadyCount = 0;
    int nifRequiredCount = 0;
    int overdueCount = 0;

    for (final s in all) {
      if (s.createdAt.isBefore(start) || !s.createdAt.isBefore(end)) continue;
      if (s.payment.status == PaymentStatus.paid) {
        paidRevenue += s.price;
        paidCount++;
      } else if (s.payment.status == PaymentStatus.unpaid) {
        unpaidRevenue += s.price;
        unpaidCount++;
      }
      if (SaleFilter.pendingShipment.test(s)) pendingShipmentCount++;
      if (SaleFilter.assemblyNotReady.test(s) && active(s)) assemblyNotReadyCount++;
      if (SaleFilter.nifRequired.test(s) && active(s) && !s.atSubmissionDone) nifRequiredCount++;
      if (SaleFilter.overdue.test(s, now: now)) overdueCount++;
    }

    return DashboardStats(
      paidRevenue: paidRevenue,
      unpaidRevenue: unpaidRevenue,
      paidCount: paidCount,
      unpaidCount: unpaidCount,
      pendingShipmentCount: pendingShipmentCount,
      assemblyNotReadyCount: assemblyNotReadyCount,
      nifRequiredCount: nifRequiredCount,
      overdueCount: overdueCount,
    );
  }
}
