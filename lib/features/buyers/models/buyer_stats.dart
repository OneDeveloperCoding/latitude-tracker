import '../../sales/models/sale.dart';

class BuyerStats {
  final int saleCount;
  final DateTime? lastPurchaseAt;
  final double totalPaid;
  final double unpaidBalance;
  final double averageSaleValue;

  const BuyerStats({
    required this.saleCount,
    required this.totalPaid,
    required this.unpaidBalance,
    required this.averageSaleValue,
    this.lastPurchaseAt,
  });

  static const empty = BuyerStats(
    saleCount: 0,
    totalPaid: 0,
    unpaidBalance: 0,
    averageSaleValue: 0,
  );

  factory BuyerStats.compute(List<Sale> sales) {
    if (sales.isEmpty) return BuyerStats.empty;

    final lastSale =
        sales.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
    final totalPaid = sales
        .where((s) => s.payment.status == PaymentStatus.paid)
        .fold(0.0, (sum, s) => sum + s.totalPrice);
    final unpaidBalance = sales
        .where((s) => s.payment.status == PaymentStatus.unpaid)
        .fold(0.0, (sum, s) => sum + s.totalPrice);
    final averageSaleValue =
        sales.fold(0.0, (acc, s) => acc + s.totalPrice) / sales.length;

    return BuyerStats(
      saleCount: sales.length,
      lastPurchaseAt: lastSale.createdAt,
      totalPaid: totalPaid,
      unpaidBalance: unpaidBalance,
      averageSaleValue: averageSaleValue,
    );
  }
}
