import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/models/sale_filter.dart';

enum SortOrder { newestFirst, oldestFirst, priceHigh, priceLow }

class SalesListFilters {
  const SalesListFilters({
    this.activeFilters = const {},
    this.categoryFilters = const {},
    this.selectedYear,
    this.selectedMonth,
    this.buyerFilter,
    this.sortOrder = SortOrder.newestFirst,
    this.searchQuery = '',
    this.postalCodePrefix,
  }) : assert(
          selectedMonth == null || selectedYear != null,
          'selectedMonth requires selectedYear to be set',
        );

  final Set<SaleFilter> activeFilters;
  final Set<String> categoryFilters;
  final int? selectedYear;
  final int? selectedMonth;
  final Buyer? buyerFilter;
  final SortOrder sortOrder;
  final String searchQuery;

  /// When set, filters to sales whose shipment postal code starts with this
  /// CP4 prefix and overrides the active-only default so delivered sales are
  /// also shown.
  final String? postalCodePrefix;

  SalesListFilters copyWith({
    Set<SaleFilter>? activeFilters,
    Set<String>? categoryFilters,
    int? selectedYear,
    bool clearYear = false,
    int? selectedMonth,
    bool clearMonth = false,
    Buyer? buyerFilter,
    bool clearBuyer = false,
    SortOrder? sortOrder,
    String? searchQuery,
    String? postalCodePrefix,
    bool clearPostalCodePrefix = false,
  }) {
    return SalesListFilters(
      activeFilters: activeFilters ?? this.activeFilters,
      categoryFilters: categoryFilters ?? this.categoryFilters,
      selectedYear: clearYear ? null : (selectedYear ?? this.selectedYear),
      selectedMonth: clearMonth ? null : (selectedMonth ?? this.selectedMonth),
      buyerFilter: clearBuyer ? null : (buyerFilter ?? this.buyerFilter),
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
      postalCodePrefix: clearPostalCodePrefix
          ? null
          : (postalCodePrefix ?? this.postalCodePrefix),
    );
  }
}

class SalesListResult {
  const SalesListResult({
    required this.filteredSales,
    required this.groupedSales,
    required this.availableYears,
    required this.monthsByYear,
    required this.availableCategories,
    required this.buyerNifById,
  });

  final List<Sale> filteredSales;
  final Map<String, List<Sale>> groupedSales;

  /// Years with at least one Sale, newest first.
  final List<int> availableYears;

  /// Months (1–12) present per year, sorted ascending.
  final Map<int, List<int>> monthsByYear;

  /// Distinct item categories across all sales, sorted ascending.
  final List<String> availableCategories;

  /// NIF per buyerId — avoids O(n_buyers) scan per card per build.
  final Map<String, String?> buyerNifById;
}
