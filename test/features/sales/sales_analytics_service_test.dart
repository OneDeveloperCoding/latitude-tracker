import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sales_analytics_service.dart';
import 'package:test/test.dart';

import '../../helpers/sale_factory.dart';

void main() {
  final jan = DateTime(2026);
  final feb = DateTime(2026, 2);
  final mar = DateTime(2026, 3);

  group('SalesAnalyticsService.computePeriodStats', () {
    test('counts only paid sales within the period', () {
      final sales = [
        makeSale(price: 100, createdAt: jan),
        makeSale(payment: PaymentStatus.unpaid, createdAt: jan),
        makeSale(price: 200, createdAt: mar),
      ];

      final result = SalesAnalyticsService.computePeriodStats(sales, jan, feb);

      expect(result.revenue, 100);
      expect(result.count, 1);
    });

    test('sums revenue of all paid sales in period', () {
      final sales = [
        makeSale(price: 40, createdAt: jan),
        makeSale(price: 60, createdAt: jan),
      ];

      final result = SalesAnalyticsService.computePeriodStats(sales, jan, feb);

      expect(result.revenue, 100);
      expect(result.count, 2);
    });

    test('returns zero revenue and count for empty period', () {
      final result = SalesAnalyticsService.computePeriodStats([], jan, feb);

      expect(result.revenue, 0);
      expect(result.count, 0);
    });

    test('with category filter sums only item prices for that category', () {
      final sale = makeSale(
        createdAt: jan,
        items: [
          makeSaleItem(category: 'Colares', price: 60),
          makeSaleItem(id: 'item-2', category: 'Brincos', price: 40),
        ],
      );

      final result = SalesAnalyticsService.computePeriodStats(
          [sale], jan, feb,
          category: 'Colares');

      expect(result.revenue, 60);
      expect(result.count, 1);
    });

    test('with category filter excludes sales with no matching items', () {
      final sales = [
        makeSale(category: 'Colares', price: 80, createdAt: jan),
        makeSale(category: 'Brincos', createdAt: jan),
      ];

      final result = SalesAnalyticsService.computePeriodStats(
          sales, jan, feb,
          category: 'Chapéus');

      expect(result.revenue, 0);
      expect(result.count, 0);
    });

    test('with category filter ignores unpaid sales', () {
      final sales = [
        makeSale(
            category: 'Colares',
            price: 100,
            createdAt: jan,
            payment: PaymentStatus.unpaid),
      ];

      final result = SalesAnalyticsService.computePeriodStats(
          sales, jan, feb,
          category: 'Colares');

      expect(result.revenue, 0);
      expect(result.count, 0);
    });
  });

  group('SalesAnalyticsService.computeCategoryBreakdown', () {
    test('sums item prices per category for paid sales', () {
      final sale = makeSale(
        createdAt: jan,
        items: [
          makeSaleItem(category: 'Colares', price: 60),
          makeSaleItem(id: 'item-2', category: 'Brincos', price: 40),
        ],
      );

      final result =
          SalesAnalyticsService.computeCategoryBreakdown([sale], jan, feb);

      expect(result.length, 2);
      expect(result[0].category, 'Colares');
      expect(result[0].revenue, 60);
      expect(result[1].category, 'Brincos');
      expect(result[1].revenue, 40);
    });

    test('excludes unpaid sales', () {
      final sales = [
        makeSale(
            category: 'Colares',
            price: 80,
            createdAt: jan,
            payment: PaymentStatus.unpaid),
      ];

      final result =
          SalesAnalyticsService.computeCategoryBreakdown(sales, jan, feb);

      expect(result, isEmpty);
    });

    test('excludes sales outside the period', () {
      final sales = [
        makeSale(category: 'Colares', price: 80, createdAt: mar),
      ];

      final result =
          SalesAnalyticsService.computeCategoryBreakdown(sales, jan, feb);

      expect(result, isEmpty);
    });

    test('returns categories sorted by revenue descending', () {
      final sales = [
        makeSale(category: 'Brincos', price: 30, createdAt: jan),
        makeSale(category: 'Colares', price: 80, createdAt: jan),
        makeSale(category: 'Chapéus', createdAt: jan),
      ];

      final result =
          SalesAnalyticsService.computeCategoryBreakdown(sales, jan, feb);

      expect(result.map((e) => e.category).toList(),
          ['Colares', 'Chapéus', 'Brincos']);
    });
  });

  group('SalesAnalyticsService.computePaymentMethodBreakdown', () {
    test('groups paid sales by payment method', () {
      final sales = [
        makeSale(price: 60, createdAt: jan),
        makeSale(method: PaymentMethod.cash, price: 40, createdAt: jan),
        makeSale(price: 30, createdAt: jan),
      ];

      final result =
          SalesAnalyticsService.computePaymentMethodBreakdown(sales, jan, feb);

      expect(result[PaymentMethod.mbWay]?.revenue, 90);
      expect(result[PaymentMethod.mbWay]?.count, 2);
      expect(result[PaymentMethod.cash]?.revenue, 40);
      expect(result[PaymentMethod.cash]?.count, 1);
    });

    test('excludes unpaid sales', () {
      final sales = [
        makeSale(
            price: 100,
            createdAt: jan,
            payment: PaymentStatus.unpaid),
      ];

      final result =
          SalesAnalyticsService.computePaymentMethodBreakdown(sales, jan, feb);

      expect(result, isEmpty);
    });

    test('excludes sales outside the period', () {
      final sales = [
        makeSale(price: 100, createdAt: mar),
      ];

      final result =
          SalesAnalyticsService.computePaymentMethodBreakdown(sales, jan, feb);

      expect(result, isEmpty);
    });

    test('tracks revolut and paypal as distinct methods', () {
      final sales = [
        makeSale(method: PaymentMethod.revolut, price: 60, createdAt: jan),
        makeSale(method: PaymentMethod.paypal, price: 40, createdAt: jan),
      ];

      final result =
          SalesAnalyticsService.computePaymentMethodBreakdown(sales, jan, feb);

      expect(result[PaymentMethod.revolut]?.revenue, 60);
      expect(result[PaymentMethod.revolut]?.count, 1);
      expect(result[PaymentMethod.paypal]?.revenue, 40);
      expect(result[PaymentMethod.paypal]?.count, 1);
    });
  });
}
