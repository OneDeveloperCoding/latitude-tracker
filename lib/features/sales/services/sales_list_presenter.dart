import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/models/sale_filter.dart';
import 'package:latitude_tracker/features/sales/models/sales_list_filters.dart';
import 'package:latitude_tracker/features/sales/services/sale_grouper.dart';

class SalesListPresenter {
  SalesListPresenter._();

  static SalesListResult compute(
    List<Sale> allSales,
    List<Buyer> allBuyers,
    SalesListFilters filters, {
    DateTime? now,
  }) {
    var sales = _applyFilter(allSales, filters, now: now);
    sales = _applySearch(sales, filters.searchQuery);
    sales = _applySort(sales, filters.sortOrder);

    final grouped = filters.selectedYear != null
        ? SaleGrouper.byCreatedMonth(sales)
        : SaleGrouper.byWeek(sales, now: now);

    final monthsMap = <int, Set<int>>{};
    for (final s in allSales) {
      (monthsMap[s.createdAt.year] ??= {}).add(s.createdAt.month);
    }
    final availableYears = monthsMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final monthsByYear = monthsMap.map(
      (y, months) => MapEntry(y, months.toList()..sort()),
    );

    return SalesListResult(
      filteredSales: sales,
      groupedSales: grouped,
      availableYears: availableYears,
      monthsByYear: monthsByYear,
      buyerNifById: {for (final b in allBuyers) b.id: b.nif},
    );
  }

  static List<Sale> _applyFilter(
    List<Sale> sales,
    SalesListFilters filters, {
    DateTime? now,
  }) {
    var result = List<Sale>.from(sales);

    // Active-only default: hide delivered unless a year is selected or a
    // postal prefix scope is active (geographic view shows all time).
    if (filters.selectedYear == null && filters.postalCodePrefix == null) {
      result = result
          .where((s) => s.shipment.status != ShipmentStatus.delivered)
          .toList();
    }

    if (filters.postalCodePrefix != null) {
      result = result.where((s) {
        final pc = s.shipment.postalCode;
        return pc != null && pc.startsWith('${filters.postalCodePrefix}-');
      }).toList();
    }

    if (filters.selectedYear != null) {
      result = result
          .where((s) => s.createdAt.year == filters.selectedYear)
          .toList();
      if (filters.selectedMonth != null) {
        result = result
            .where((s) => s.createdAt.month == filters.selectedMonth)
            .toList();
      }
    }

    if (filters.buyerFilter != null) {
      result =
          result.where((s) => s.buyerId == filters.buyerFilter!.id).toList();
    }

    if (filters.categoryFilters.isNotEmpty) {
      result = result
          .where(
            (s) => s.items
                .any((i) => filters.categoryFilters.contains(i.category)),
          )
          .toList();
    }

    if (filters.activeFilters.isNotEmpty) {
      final today = now ?? DateTime.now();
      result = result
          .where((s) => testSaleFilters(s, filters.activeFilters, now: today))
          .toList();
    }

    return result;
  }

  static List<Sale> _applySearch(List<Sale> sales, String query) {
    if (query.isEmpty) return sales;
    final q = query.toLowerCase();
    return sales
        .where(
          (s) =>
              s.buyerName.toLowerCase().contains(q) ||
              s.items.any((i) => i.description.toLowerCase().contains(q)),
        )
        .toList();
  }

  static List<Sale> _applySort(List<Sale> sales, SortOrder order) {
    if (order == SortOrder.newestFirst) return sales;
    final sorted = List<Sale>.from(sales);
    switch (order) {
      case SortOrder.oldestFirst:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOrder.priceHigh:
        sorted.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
      case SortOrder.priceLow:
        sorted.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
      case SortOrder.newestFirst:
        break;
    }
    return sorted;
  }
}
