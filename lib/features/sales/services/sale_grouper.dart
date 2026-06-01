import 'package:intl/intl.dart';

import '../models/sale.dart';

/// Groups a list of [Sale]s into ordered buckets for the timeline view.
///
/// Bucket keys are always English strings — callers translate them for display.
/// Fixed buckets appear first in this order, followed by past months descending.
class SaleGrouper {
  SaleGrouper._();

  static const _fixedOrder = ['Overdue', 'This week', 'Next week', 'Later'];

  static Map<String, List<Sale>> byWeek(List<Sale> sales) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfThisWeek = today.subtract(Duration(days: now.weekday - 1));
    final startOfNextWeek = startOfThisWeek.add(const Duration(days: 7));
    final endOfNextWeek = startOfNextWeek.add(const Duration(days: 7));
    final Map<String, List<Sale>> groups = {};

    for (final sale in sales) {
      groups
          .putIfAbsent(
              _weekKey(sale, startOfThisWeek, startOfNextWeek, endOfNextWeek),
              () => [])
          .add(sale);
    }

    final sorted = <String, List<Sale>>{};
    for (final key in _fixedOrder) {
      if (groups.containsKey(key)) sorted[key] = groups[key]!;
    }
    for (final key in groups.keys) {
      if (!_fixedOrder.contains(key)) sorted[key] = groups[key]!;
    }
    return sorted;
  }

  static String _weekKey(Sale sale, DateTime startOfThisWeek,
      DateTime startOfNextWeek, DateTime endOfNextWeek) {
    final relevantDate = sale.scheduledDate ?? sale.createdAt;

    if (sale.scheduledDate != null &&
        sale.scheduledDate!.isBefore(startOfThisWeek) &&
        sale.shipment.status != ShipmentStatus.delivered) {
      return 'Overdue';
    }
    if (relevantDate.isAfter(startOfThisWeek.subtract(const Duration(seconds: 1))) &&
        relevantDate.isBefore(startOfNextWeek)) {
      return 'This week';
    }
    if (relevantDate.isAfter(startOfNextWeek.subtract(const Duration(seconds: 1))) &&
        relevantDate.isBefore(endOfNextWeek)) {
      return 'Next week';
    }
    if (relevantDate.isAfter(endOfNextWeek)) {
      return 'Later';
    }
    return DateFormat('MMMM yyyy').format(relevantDate);
  }
}
