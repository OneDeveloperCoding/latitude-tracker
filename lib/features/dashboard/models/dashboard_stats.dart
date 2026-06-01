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
    final period = all
        .where((s) => !s.createdAt.isBefore(start) && s.createdAt.isBefore(end))
        .toList();

    final now = DateTime.now();

    // Action counts exclude already-delivered sales — those need no further action.
    bool active(Sale s) => s.shipment.status != ShipmentStatus.delivered;

    return DashboardStats(
      paidRevenue: period
          .where((s) => s.payment.status == PaymentStatus.paid)
          .fold(0.0, (sum, s) => sum + s.price),
      unpaidRevenue: period
          .where((s) => s.payment.status == PaymentStatus.unpaid)
          .fold(0.0, (sum, s) => sum + s.price),
      paidCount:
          period.where((s) => s.payment.status == PaymentStatus.paid).length,
      unpaidCount:
          period.where((s) => s.payment.status == PaymentStatus.unpaid).length,
      pendingShipmentCount:
          period.where((s) => SaleFilter.pendingShipment.test(s)).length,
      assemblyNotReadyCount: period
          .where((s) => SaleFilter.assemblyNotReady.test(s) && active(s))
          .length,
      nifRequiredCount: period
          .where((s) =>
              SaleFilter.nifRequired.test(s) && active(s) && !s.atSubmissionDone)
          .length,
      overdueCount: period
          .where((s) => SaleFilter.overdue.test(s, now: now))
          .length,
    );
  }
}
