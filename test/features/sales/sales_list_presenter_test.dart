import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/models/sales_list_filters.dart';
import 'package:latitude_tracker/features/sales/services/sales_list_presenter.dart';

import '../../helpers/sale_factory.dart';

void main() {
  // A fixed reference point so test output is deterministic.
  final now = DateTime(2026, 6, 15);

  Sale saleDelivered({DateTime? createdAt}) => makeSale(
        shipmentStatus: ShipmentStatus.delivered,
        createdAt: createdAt ?? DateTime(2026, 3),
      );

  Sale saleActive({DateTime? createdAt, String category = 'necklace'}) =>
      makeSale(
        createdAt: createdAt ?? DateTime(2026, 6),
        category: category,
      );

  Sale saleWithBuyer(String buyerId, {String buyerName = 'Buyer'}) => Sale(
        id: 'sale-$buyerId',
        buyerId: buyerId,
        buyerName: buyerName,
        items: const [
          SaleItem(
            id: 'item-1',
            description: 'Ring',
            category: 'rings',
            price: 30,
            assemblyStatus: AssemblyStatus.ready,
          ),
        ],
        payment: const SalePayment(
          status: PaymentStatus.paid,
          method: PaymentMethod.mbWay,
        ),
        shipment: const SaleShipment(
          type: DeliveryType.shipping,
          status: ShipmentStatus.pending,
        ),
        requiresNif: false,
        createdAt: DateTime(2026, 6),
      );

  Sale saleWithPostalCode(String postalCode) => Sale(
        id: 'sale-postal',
        buyerId: 'b1',
        buyerName: 'Test',
        items: const [
          SaleItem(
            id: 'item-1',
            description: 'Hat',
            category: 'hats',
            price: 25,
            assemblyStatus: AssemblyStatus.ready,
          ),
        ],
        payment: const SalePayment(
          status: PaymentStatus.paid,
          method: PaymentMethod.cash,
        ),
        shipment: SaleShipment(
          type: DeliveryType.shipping,
          status: ShipmentStatus.delivered,
          postalCode: postalCode,
        ),
        requiresNif: false,
        createdAt: DateTime(2026, 5, 10),
      );

  Buyer makeBuyer(String id, {String? nif}) => Buyer(
        id: id,
        name: 'Buyer $id',
        nif: nif,
        createdAt: DateTime(2026),
      );

  group('active-only default', () {
    test('hides delivered sales when no year selected', () {
      final sales = [saleActive(), saleDelivered()];
      final result = SalesListPresenter.compute(
        sales,
        [],
        const SalesListFilters(),
        now: now,
      );
      expect(result.filteredSales, hasLength(1));
      expect(
        result.filteredSales
            .every((s) => s.shipment.status != ShipmentStatus.delivered),
        isTrue,
      );
    });

    test('shows delivered sales when a year is selected', () {
      final sales = [saleActive(), saleDelivered()];
      final result = SalesListPresenter.compute(
        sales,
        [],
        const SalesListFilters(selectedYear: 2026),
        now: now,
      );
      expect(result.filteredSales, hasLength(2));
    });
  });

  group('year filter', () {
    test('scopes to selected year', () {
      final sales = [
        saleActive(createdAt: DateTime(2026)),
        saleActive(createdAt: DateTime(2025, 6)),
      ];
      final result = SalesListPresenter.compute(
        sales,
        [],
        const SalesListFilters(selectedYear: 2026),
        now: now,
      );
      expect(result.filteredSales, hasLength(1));
      expect(result.filteredSales.first.createdAt.year, 2026);
    });

    test('scopes to selected year + month', () {
      final sales = [
        saleActive(createdAt: DateTime(2026, 3)),
        saleActive(createdAt: DateTime(2026, 6)),
      ];
      final result = SalesListPresenter.compute(
        sales,
        [],
        const SalesListFilters(selectedYear: 2026, selectedMonth: 3),
        now: now,
      );
      expect(result.filteredSales, hasLength(1));
      expect(result.filteredSales.first.createdAt.month, 3);
    });
  });

  group('buyer filter', () {
    test('returns only sales for the selected buyer', () {
      final b1 = makeBuyer('b1');
      final sales = [saleWithBuyer('b1'), saleWithBuyer('b2')];
      final result = SalesListPresenter.compute(
        sales,
        [b1],
        SalesListFilters(buyerFilter: b1),
        now: now,
      );
      expect(result.filteredSales, hasLength(1));
      expect(result.filteredSales.first.buyerId, 'b1');
    });
  });

  group('category filter', () {
    test('returns only sales with a matching category', () {
      final sales = [
        saleActive(),
        saleActive(category: 'earrings'),
      ];
      final result = SalesListPresenter.compute(
        sales,
        [],
        const SalesListFilters(categoryFilters: {'necklace'}),
        now: now,
      );
      expect(result.filteredSales, hasLength(1));
      expect(result.filteredSales.first.items.first.category, 'necklace');
    });
  });

  group('search', () {
    test('matches buyer name case-insensitively', () {
      final sales = [
        makeSale(createdAt: now),
        Sale(
          id: 'other',
          buyerId: 'b2',
          buyerName: 'Maria',
          items: const [
            SaleItem(
              id: 'i1',
              description: 'Earring',
              category: 'earrings',
              price: 20,
              assemblyStatus: AssemblyStatus.ready,
            ),
          ],
          payment: const SalePayment(
            status: PaymentStatus.paid,
            method: PaymentMethod.mbWay,
          ),
          shipment: const SaleShipment(
            type: DeliveryType.pickup,
            status: ShipmentStatus.pending,
          ),
          requiresNif: false,
          createdAt: now,
        ),
      ];
      final result = SalesListPresenter.compute(
        sales,
        [],
        const SalesListFilters(searchQuery: 'maria'),
        now: now,
      );
      expect(result.filteredSales, hasLength(1));
      expect(result.filteredSales.first.buyerName, 'Maria');
    });

    test('matches item description case-insensitively', () {
      final sales = [saleActive()]; // description = 'Test Item'
      final result = SalesListPresenter.compute(
        sales,
        [],
        const SalesListFilters(searchQuery: 'test item'),
        now: now,
      );
      expect(result.filteredSales, hasLength(1));
    });

    test('returns empty when query matches nothing', () {
      final result = SalesListPresenter.compute(
        [saleActive()],
        [],
        const SalesListFilters(searchQuery: 'zzzzzz'),
        now: now,
      );
      expect(result.filteredSales, isEmpty);
    });
  });

  group('sort orders', () {
    late Sale older;
    late Sale newer;

    setUp(() {
      older = saleActive(createdAt: DateTime(2026));
      newer = saleActive(createdAt: DateTime(2026, 6));
    });

    test('newestFirst preserves incoming store order', () {
      // The store delivers newest-first; newestFirst applies no reordering.
      final result = SalesListPresenter.compute(
        [newer, older],
        [],
        const SalesListFilters(
          selectedYear: 2026,
        ),
        now: now,
      );
      expect(result.filteredSales.first.createdAt.month, 6);
    });

    test('oldestFirst returns oldest sale first', () {
      final result = SalesListPresenter.compute(
        [newer, older],
        [],
        const SalesListFilters(
          selectedYear: 2026,
          sortOrder: SortOrder.oldestFirst,
        ),
        now: now,
      );
      expect(result.filteredSales.first.createdAt.month, 1);
    });

    test('priceHigh returns highest price first', () {
      final cheap = makeSale(price: 10, createdAt: DateTime(2026, 6));
      final expensive = makeSale(price: 100, createdAt: DateTime(2026, 6, 2));
      final result = SalesListPresenter.compute(
        [cheap, expensive],
        [],
        const SalesListFilters(
          selectedYear: 2026,
          sortOrder: SortOrder.priceHigh,
        ),
        now: now,
      );
      expect(result.filteredSales.first.totalPrice, 100);
    });

    test('priceLow returns lowest price first', () {
      final cheap = makeSale(price: 10, createdAt: DateTime(2026, 6));
      final expensive = makeSale(price: 100, createdAt: DateTime(2026, 6, 2));
      final result = SalesListPresenter.compute(
        [cheap, expensive],
        [],
        const SalesListFilters(
          selectedYear: 2026,
          sortOrder: SortOrder.priceLow,
        ),
        now: now,
      );
      expect(result.filteredSales.first.totalPrice, 10);
    });
  });

  group('postal-code-prefix scope', () {
    test('includes delivered sales and filters by prefix', () {
      final matching = saleWithPostalCode('3000-550');
      final wrongPrefix = saleWithPostalCode('1200-100');
      final noPostalCode = makeSale(
        shipmentStatus: ShipmentStatus.delivered,
        createdAt: DateTime(2026, 5),
      );

      final result = SalesListPresenter.compute(
        [matching, wrongPrefix, noPostalCode],
        [],
        const SalesListFilters(postalCodePrefix: '3000'),
        now: now,
      );
      expect(result.filteredSales, hasLength(1));
      expect(result.filteredSales.first.shipment.postalCode, '3000-550');
    });
  });

  group('availableYears and monthsByYear', () {
    test('lists unique years newest first', () {
      final sales = [
        saleActive(createdAt: DateTime(2024, 3)),
        saleActive(createdAt: DateTime(2025, 6)),
        saleActive(createdAt: DateTime(2025, 9)),
        saleActive(createdAt: DateTime(2026)),
      ];
      final result = SalesListPresenter.compute(
        sales,
        [],
        const SalesListFilters(),
        now: now,
      );
      expect(result.availableYears, [2026, 2025, 2024]);
    });

    test('monthsByYear lists months sorted ascending', () {
      final sales = [
        saleActive(createdAt: DateTime(2026, 6)),
        saleActive(createdAt: DateTime(2026, 3)),
        saleActive(createdAt: DateTime(2026)),
      ];
      final result = SalesListPresenter.compute(
        sales,
        [],
        const SalesListFilters(),
        now: now,
      );
      expect(result.monthsByYear[2026], [1, 3, 6]);
    });
  });

  group('buyerNifById', () {
    test('maps buyer id to nif', () {
      final b1 = makeBuyer('b1', nif: '123456789');
      final b2 = makeBuyer('b2');
      final result = SalesListPresenter.compute(
        [],
        [b1, b2],
        const SalesListFilters(),
        now: now,
      );
      expect(result.buyerNifById['b1'], '123456789');
      expect(result.buyerNifById['b2'], isNull);
    });
  });

  group('SalesListFilters.copyWith', () {
    test('clearYear sets selectedYear and selectedMonth to null', () {
      const f = SalesListFilters(selectedYear: 2026, selectedMonth: 3);
      final cleared = f.copyWith(clearYear: true, clearMonth: true);
      expect(cleared.selectedYear, isNull);
      expect(cleared.selectedMonth, isNull);
    });

    test('clearBuyer sets buyerFilter to null', () {
      final buyer = makeBuyer('b1');
      final f = SalesListFilters(buyerFilter: buyer);
      expect(f.copyWith(clearBuyer: true).buyerFilter, isNull);
    });

    test('preserves unspecified fields', () {
      const f = SalesListFilters(
        searchQuery: 'hello',
        sortOrder: SortOrder.priceLow,
      );
      final updated = f.copyWith(searchQuery: 'world');
      expect(updated.sortOrder, SortOrder.priceLow);
      expect(updated.searchQuery, 'world');
    });
  });
}
