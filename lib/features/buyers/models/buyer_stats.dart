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

    DateTime? lastPurchaseAt;
    double totalPaid = 0;
    double unpaidBalance = 0;
    double totalValue = 0;

    for (final sale in sales) {
      if (lastPurchaseAt == null || sale.createdAt.isAfter(lastPurchaseAt)) {
        lastPurchaseAt = sale.createdAt;
      }
      switch (sale.payment.status) {
        case PaymentStatus.paid:
          totalPaid += sale.totalPrice;
        case PaymentStatus.unpaid:
          unpaidBalance += sale.totalPrice;
      }
      totalValue += sale.totalPrice;
    }

    return BuyerStats(
      saleCount: sales.length,
      lastPurchaseAt: lastPurchaseAt,
      totalPaid: totalPaid,
      unpaidBalance: unpaidBalance,
      averageSaleValue: totalValue / sales.length,
    );
  }
}
