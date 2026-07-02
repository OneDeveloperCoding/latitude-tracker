import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/heat_map/services/geographic_sales_service.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/sale_factory.dart';

Sale _shippingSale(
  String? postalCode, {
  double price = 100.0,
  String? addressId,
}) => makeSale().copyWith(
  shipment: SaleShipment(
    type: DeliveryType.shipping,
    status: ShipmentStatus.delivered,
    postalCode: postalCode,
    addressId: addressId,
  ),
  items: [makeSaleItem(price: price)],
);

Sale _handDeliverySale(String? postalCode, {double price = 100.0}) =>
    makeSale(delivery: DeliveryType.handDelivery).copyWith(
      shipment: SaleShipment(
        type: DeliveryType.handDelivery,
        status: ShipmentStatus.delivered,
        postalCode: postalCode,
      ),
      items: [makeSaleItem(price: price)],
    );

Sale _pickupSale() => makeSale(delivery: DeliveryType.pickup).copyWith(
  shipment: const SaleShipment(
    type: DeliveryType.pickup,
    status: ShipmentStatus.delivered,
  ),
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('GeographicSalesService.buildRanking — Portugal section', () {
    test('groups sales by CP4 prefix', () async {
      final ranking = await GeographicSalesService.buildRanking(
        [
          _shippingSale('3000-550'),
          _shippingSale('3000-100'),
          _shippingSale('1200-001'),
        ],
        {},
      );
      expect(ranking.localities.length, 2);
      final prefixes = ranking.localities.map((r) => r.postalCode).toSet();
      expect(prefixes, containsAll(['3000', '1200']));
    });

    test('sums count and revenue per CP4', () async {
      final ranking = await GeographicSalesService.buildRanking(
        [
          _shippingSale('4000-001', price: 80),
          _shippingSale('4000-002', price: 120),
        ],
        {},
      );
      expect(ranking.localities.length, 1);
      expect(ranking.localities.first.count, 2);
      expect(ranking.localities.first.revenue, closeTo(200.0, 0.01));
    });

    test('includes hand delivery sales', () async {
      final ranking = await GeographicSalesService.buildRanking(
        [_handDeliverySale('2000-001')],
        {},
      );
      expect(ranking.localities.length, 1);
      expect(ranking.localities.first.postalCode, '2000');
    });

    test('excludes pickup sales with no postal code', () async {
      final ranking = await GeographicSalesService.buildRanking(
        [_pickupSale()],
        {},
      );
      expect(ranking.localities, isEmpty);
    });

    test(
      'locality name falls back to CP4 when prefix is not in the table',
      () async {
        final ranking = await GeographicSalesService.buildRanking(
          [_shippingSale('9999-001')],
          {},
        );
        expect(ranking.localities.first.locality, '9999');
      },
    );
  });

  group('GeographicSalesService.buildRanking — International section', () {
    test('groups non-PT sales by country from addressCountries map', () async {
      final ranking = await GeographicSalesService.buildRanking(
        [
          _shippingSale('75001', addressId: 'addr-fr', price: 90),
          _shippingSale('28001', addressId: 'addr-es', price: 60),
        ],
        {'addr-fr': 'France', 'addr-es': 'Spain'},
      );
      expect(ranking.countries.length, 2);
      final countries = ranking.countries.map((r) => r.country).toSet();
      expect(countries, containsAll(['France', 'Spain']));
    });

    test('accumulates count and revenue per country', () async {
      final ranking = await GeographicSalesService.buildRanking(
        [
          _shippingSale('75001', addressId: 'addr-fr-1', price: 50),
          _shippingSale('75002', addressId: 'addr-fr-2', price: 70),
        ],
        {'addr-fr-1': 'France', 'addr-fr-2': 'France'},
      );
      expect(ranking.countries.length, 1);
      expect(ranking.countries.first.count, 2);
      expect(ranking.countries.first.revenue, closeTo(120.0, 0.01));
    });

    test(
      'excludes non-PT sales whose addressId is absent from the lookup',
      () async {
        final ranking = await GeographicSalesService.buildRanking(
          [_shippingSale('75001', addressId: 'unknown-addr')],
          {},
        );
        expect(ranking.countries, isEmpty);
      },
    );

    test('excludes non-PT sales with no addressId', () async {
      final ranking = await GeographicSalesService.buildRanking(
        [_shippingSale('75001')],
        {},
      );
      expect(ranking.countries, isEmpty);
    });

    test(
      'excludes "Portugal" entries even if postal code does not match PT'
      ' format',
      () async {
        final ranking = await GeographicSalesService.buildRanking(
          [_shippingSale('75001', addressId: 'addr-pt')],
          {'addr-pt': 'Portugal'},
        );
        expect(ranking.countries, isEmpty);
      },
    );
  });

  group('GeographicSalesService.buildRanking — isEmpty', () {
    test('returns isEmpty true when no sales match', () async {
      final ranking = await GeographicSalesService.buildRanking([], {});
      expect(ranking.isEmpty, isTrue);
    });

    test('returns isEmpty false when Portugal section has data', () async {
      final ranking = await GeographicSalesService.buildRanking(
        [_shippingSale('1000-001')],
        {},
      );
      expect(ranking.isEmpty, isFalse);
    });
  });
}
