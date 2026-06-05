import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/buyers/models/buyer_stats.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

import '../../helpers/sale_factory.dart';

void main() {
  group('BuyerStats.compute', () {
    test('empty list returns BuyerStats.empty', () {
      final stats = BuyerStats.compute([]);
      expect(stats.saleCount, 0);
      expect(stats.totalPaid, 0);
      expect(stats.unpaidBalance, 0);
      expect(stats.averageSaleValue, 0);
      expect(stats.lastPurchaseAt, isNull);
    });

    test('counts all sales', () {
      final sales = [makeSale(), makeSale(), makeSale()];
      expect(BuyerStats.compute(sales).saleCount, 3);
    });

    test('totalPaid sums only paid sales', () {
      final sales = [
        makeSale(price: 100, payment: PaymentStatus.paid),
        makeSale(price: 50, payment: PaymentStatus.unpaid),
        makeSale(price: 30, payment: PaymentStatus.paid),
      ];
      expect(BuyerStats.compute(sales).totalPaid, 130);
    });

    test('unpaidBalance sums only unpaid sales', () {
      final sales = [
        makeSale(price: 100, payment: PaymentStatus.paid),
        makeSale(price: 50, payment: PaymentStatus.unpaid),
        makeSale(price: 20, payment: PaymentStatus.unpaid),
      ];
      expect(BuyerStats.compute(sales).unpaidBalance, 70);
    });

    test('averageSaleValue uses all sales regardless of payment status', () {
      final sales = [
        makeSale(price: 100, payment: PaymentStatus.paid),
        makeSale(price: 50, payment: PaymentStatus.unpaid),
      ];
      expect(BuyerStats.compute(sales).averageSaleValue, 75);
    });

    test('lastPurchaseAt is the most recent createdAt', () {
      final older = DateTime(2026, 1, 1);
      final newer = DateTime(2026, 6, 1);
      final sales = [
        makeSale(createdAt: older),
        makeSale(createdAt: newer),
        makeSale(createdAt: DateTime(2026, 3, 15)),
      ];
      expect(BuyerStats.compute(sales).lastPurchaseAt, newer);
    });

    test('single sale sets all fields correctly', () {
      final sale = makeSale(price: 80, payment: PaymentStatus.paid);
      final stats = BuyerStats.compute([sale]);
      expect(stats.saleCount, 1);
      expect(stats.totalPaid, 80);
      expect(stats.unpaidBalance, 0);
      expect(stats.averageSaleValue, 80);
      expect(stats.lastPurchaseAt, sale.createdAt);
    });
  });
}
