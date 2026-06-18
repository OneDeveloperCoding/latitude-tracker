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

    final (:availableYears, :monthsByYear) = _buildYearIndex(allSales);

    return SalesListResult(
      filteredSales: sales,
      groupedSales: grouped,
      availableYears: availableYears,
      monthsByYear: monthsByYear,
      buyerNifById: {for (final b in allBuyers) b.id: b.nif},
    );
  }

  static ({List<int> availableYears, Map<int, List<int>> monthsByYear})
      _buildYearIndex(List<Sale> sales) {
    final monthsMap = <int, Set<int>>{};
    for (final s in sales) {
      (monthsMap[s.createdAt.year] ??= {}).add(s.createdAt.month);
    }
    final availableYears = monthsMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final monthsByYear = monthsMap.map(
      (y, months) => MapEntry(y, months.toList()..sort()),
    );
    return (availableYears: availableYears, monthsByYear: monthsByYear);
  }

  static List<Sale> _applyFilter(
    List<Sale> sales,
    SalesListFilters filters, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    return sales.where((s) => _passesScopeFilters(s, filters, today)).toList();
  }

  // Tests one sale against all filter dimensions using early returns.
  // History mode (year selected or postal prefix active) lifts the active-only
  // default so delivered sales are included.
  static bool _passesScopeFilters(Sale s, SalesListFilters f, DateTime now) {
    final isHistoryMode = f.selectedYear != null || f.postalCodePrefix != null;
    if (!isHistoryMode && s.shipment.status == ShipmentStatus.delivered) {
      return false;
    }
    if (f.postalCodePrefix != null) {
      final pc = s.shipment.postalCode;
      if (pc == null || !pc.startsWith('${f.postalCodePrefix}-')) return false;
    }
    if (f.selectedYear != null) {
      if (s.createdAt.year != f.selectedYear) return false;
      if (f.selectedMonth != null && s.createdAt.month != f.selectedMonth) {
        return false;
      }
    }
    if (f.buyerFilter != null && s.buyerId != f.buyerFilter!.id) return false;
    if (f.categoryFilters.isNotEmpty &&
        !s.items.any((i) => f.categoryFilters.contains(i.category))) {
      return false;
    }
    if (f.activeFilters.isNotEmpty &&
        !testSaleFilters(s, f.activeFilters, now: now)) {
      return false;
    }
    return true;
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
    switch (order) {
      case SortOrder.newestFirst:
        return sales;
      case SortOrder.oldestFirst:
        return List<Sale>.from(sales)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOrder.priceHigh:
        return List<Sale>.from(sales)
          ..sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
      case SortOrder.priceLow:
        return List<Sale>.from(sales)
          ..sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
    }
  }
}
