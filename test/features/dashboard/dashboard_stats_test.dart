import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/dashboard/models/dashboard_stats.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

import '../../helpers/sale_factory.dart';

void main() {
  final jan = DateTime(2026, 1, 1);
  final feb = DateTime(2026, 2, 1);
  final mar = DateTime(2026, 3, 1);

  group('DashboardStats.computeTopCategories', () {
    test('returns top categories by revenue descending', () {
      final sales = [
        makeSale(category: 'Colares', price: 80, createdAt: jan),
        makeSale(category: 'Brincos', price: 30, createdAt: jan),
        makeSale(category: 'Chapéus', price: 50, createdAt: jan),
      ];

      final result = DashboardStats.computeTopCategories(sales, jan, feb);

      expect(result.length, 3);
      expect(result[0].category, 'Colares');
      expect(result[1].category, 'Chapéus');
      expect(result[2].category, 'Brincos');
    });

    test('sums revenue across multiple sales in same category', () {
      final sales = [
        makeSale(category: 'Colares', price: 40, createdAt: jan),
        makeSale(category: 'Colares', price: 60, createdAt: jan),
        makeSale(category: 'Brincos', price: 90, createdAt: jan),
      ];

      final result = DashboardStats.computeTopCategories(sales, jan, feb);

      expect(result[0].category, 'Colares');
      expect(result[0].revenue, 100);
      expect(result[1].revenue, 90);
    });

    test('limits results to the requested count', () {
      final sales = [
        makeSale(category: 'A', price: 10, createdAt: jan),
        makeSale(category: 'B', price: 20, createdAt: jan),
        makeSale(category: 'C', price: 30, createdAt: jan),
        makeSale(category: 'D', price: 40, createdAt: jan),
      ];

      final result =
          DashboardStats.computeTopCategories(sales, jan, feb, limit: 2);

      expect(result.length, 2);
      expect(result[0].category, 'D');
      expect(result[1].category, 'C');
    });

    test('excludes sales outside the period window', () {
      final sales = [
        makeSale(category: 'Colares', price: 80, createdAt: jan),
        makeSale(category: 'Brincos', price: 200, createdAt: mar),
      ];

      final result = DashboardStats.computeTopCategories(sales, jan, feb);

      expect(result.length, 1);
      expect(result[0].category, 'Colares');
    });

    test('returns empty list when no sales in period', () {
      final sales = [makeSale(createdAt: mar)];

      final result = DashboardStats.computeTopCategories(sales, jan, feb);

      expect(result, isEmpty);
    });

    test('includes items from multi-item sales', () {
      final sale = makeSale(
        createdAt: jan,
        items: [
          makeSaleItem(category: 'Colares', price: 60),
          makeSaleItem(id: 'item-2', category: 'Brincos', price: 40),
        ],
      );

      final result = DashboardStats.computeTopCategories([sale], jan, feb);

      expect(result.length, 2);
      expect(result[0].category, 'Colares');
      expect(result[0].revenue, 60);
      expect(result[1].revenue, 40);
    });
  });

  group('DashboardStats.computePeriodStats', () {
    test('counts only paid sales within the period', () {
      final sales = [
        makeSale(payment: PaymentStatus.paid, price: 100, createdAt: jan),
        makeSale(payment: PaymentStatus.unpaid, price: 50, createdAt: jan),
        makeSale(payment: PaymentStatus.paid, price: 200, createdAt: mar),
      ];

      final result = DashboardStats.computePeriodStats(sales, jan, feb);

      expect(result.revenue, 100);
      expect(result.count, 1);
    });

    test('sums revenue of all paid sales in period', () {
      final sales = [
        makeSale(payment: PaymentStatus.paid, price: 40, createdAt: jan),
        makeSale(payment: PaymentStatus.paid, price: 60, createdAt: jan),
      ];

      final result = DashboardStats.computePeriodStats(sales, jan, feb);

      expect(result.revenue, 100);
      expect(result.count, 2);
    });

    test('returns zero revenue and count for empty period', () {
      final result = DashboardStats.computePeriodStats([], jan, feb);

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

      final result =
          DashboardStats.computePeriodStats([sale], jan, feb, category: 'Colares');

      expect(result.revenue, 60);
      expect(result.count, 1);
    });

    test('with category filter excludes sales with no matching items', () {
      final sales = [
        makeSale(category: 'Colares', price: 80, createdAt: jan),
        makeSale(category: 'Brincos', price: 50, createdAt: jan),
      ];

      final result =
          DashboardStats.computePeriodStats(sales, jan, feb, category: 'Chapéus');

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

      final result =
          DashboardStats.computePeriodStats(sales, jan, feb, category: 'Colares');

      expect(result.revenue, 0);
      expect(result.count, 0);
    });
  });

  group('DashboardStats.computeCategoryBreakdown', () {
    test('sums item prices per category for paid sales', () {
      final sale = makeSale(
        createdAt: jan,
        items: [
          makeSaleItem(category: 'Colares', price: 60),
          makeSaleItem(id: 'item-2', category: 'Brincos', price: 40),
        ],
      );

      final result = DashboardStats.computeCategoryBreakdown([sale], jan, feb);

      expect(result.length, 2);
      expect(result[0].category, 'Colares');
      expect(result[0].revenue, 60);
      expect(result[1].category, 'Brincos');
      expect(result[1].revenue, 40);
    });

    test('excludes unpaid sales', () {
      final sales = [
        makeSale(category: 'Colares', price: 80, createdAt: jan, payment: PaymentStatus.unpaid),
      ];

      final result = DashboardStats.computeCategoryBreakdown(sales, jan, feb);

      expect(result, isEmpty);
    });

    test('excludes sales outside the period', () {
      final sales = [
        makeSale(category: 'Colares', price: 80, createdAt: mar),
      ];

      final result = DashboardStats.computeCategoryBreakdown(sales, jan, feb);

      expect(result, isEmpty);
    });

    test('returns categories sorted by revenue descending', () {
      final sales = [
        makeSale(category: 'Brincos', price: 30, createdAt: jan),
        makeSale(category: 'Colares', price: 80, createdAt: jan),
        makeSale(category: 'Chapéus', price: 50, createdAt: jan),
      ];

      final result = DashboardStats.computeCategoryBreakdown(sales, jan, feb);

      expect(result.map((e) => e.category).toList(),
          ['Colares', 'Chapéus', 'Brincos']);
    });
  });

  group('DashboardStats.computePaymentMethodBreakdown', () {
    test('groups paid sales by payment method', () {
      final sales = [
        makeSale(method: PaymentMethod.mbWay, price: 60, createdAt: jan),
        makeSale(method: PaymentMethod.cash, price: 40, createdAt: jan),
        makeSale(method: PaymentMethod.mbWay, price: 30, createdAt: jan),
      ];

      final result =
          DashboardStats.computePaymentMethodBreakdown(sales, jan, feb);

      expect(result[PaymentMethod.mbWay]?.revenue, 90);
      expect(result[PaymentMethod.mbWay]?.count, 2);
      expect(result[PaymentMethod.cash]?.revenue, 40);
      expect(result[PaymentMethod.cash]?.count, 1);
    });

    test('excludes unpaid sales', () {
      final sales = [
        makeSale(
            method: PaymentMethod.mbWay,
            price: 100,
            createdAt: jan,
            payment: PaymentStatus.unpaid),
      ];

      final result =
          DashboardStats.computePaymentMethodBreakdown(sales, jan, feb);

      expect(result, isEmpty);
    });

    test('excludes sales outside the period', () {
      final sales = [
        makeSale(method: PaymentMethod.mbWay, price: 100, createdAt: mar),
      ];

      final result =
          DashboardStats.computePaymentMethodBreakdown(sales, jan, feb);

      expect(result, isEmpty);
    });
  });
}
