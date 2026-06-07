import '../models/sale.dart';

class SalesAnalyticsService {
  static ({double revenue, int count}) computePeriodStats(
    List<Sale> all,
    DateTime start,
    DateTime end, {
    String? category,
  }) {
    double revenue = 0;
    int count = 0;
    for (final s in all) {
      if (s.createdAt.isBefore(start) || !s.createdAt.isBefore(end)) continue;
      if (s.payment.status != PaymentStatus.paid) continue;
      if (category == null) {
        revenue += s.totalPrice;
        count++;
      } else {
        final itemRevenue = s.items
            .where((i) => i.category == category)
            .fold(0.0, (sum, i) => sum + i.price);
        if (itemRevenue > 0) {
          revenue += itemRevenue;
          count++;
        }
      }
    }
    return (revenue: revenue, count: count);
  }

  // Per-category revenue breakdown for paid sales in the period (for stacked chart).
  static List<({String category, double revenue})> computeCategoryBreakdown(
    List<Sale> all,
    DateTime start,
    DateTime end,
  ) {
    final map = <String, double>{};
    for (final s in all) {
      if (s.createdAt.isBefore(start) || !s.createdAt.isBefore(end)) continue;
      if (s.payment.status != PaymentStatus.paid) continue;
      for (final item in s.items) {
        map[item.category] = (map[item.category] ?? 0) + item.price;
      }
    }
    return (map.entries.map((e) => (category: e.key, revenue: e.value)).toList()
          ..sort((a, b) => b.revenue.compareTo(a.revenue)));
  }

  // Revenue and sale count per payment method for paid sales in the period.
  static Map<PaymentMethod, ({double revenue, int count})>
      computePaymentMethodBreakdown(
    List<Sale> all,
    DateTime start,
    DateTime end,
  ) {
    final map = <PaymentMethod, ({double revenue, int count})>{};
    for (final s in all) {
      if (s.createdAt.isBefore(start) || !s.createdAt.isBefore(end)) continue;
      if (s.payment.status != PaymentStatus.paid) continue;
      final m = s.payment.method;
      final prev = map[m] ?? (revenue: 0.0, count: 0);
      map[m] = (revenue: prev.revenue + s.totalPrice, count: prev.count + 1);
    }
    return map;
  }
}
