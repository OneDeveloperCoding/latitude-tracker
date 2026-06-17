import 'package:test/test.dart';
import 'package:latitude_tracker/features/heat_map/services/heat_map_service.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

import '../../helpers/sale_factory.dart';

Sale _shippingSale(String? postalCode) => makeSale(
      delivery: DeliveryType.shipping,
    ).copyWith(
      shipment: SaleShipment(
        type: DeliveryType.shipping,
        status: ShipmentStatus.delivered,
        postalCode: postalCode,
      ),
    );

Sale _handDeliverySale(String? postalCode) => makeSale(
      delivery: DeliveryType.handDelivery,
    ).copyWith(
      shipment: SaleShipment(
        type: DeliveryType.handDelivery,
        status: ShipmentStatus.delivered,
        postalCode: postalCode,
      ),
    );

Sale _pickupSale(String? postalCode) => makeSale(
      delivery: DeliveryType.pickup,
    ).copyWith(
      shipment: SaleShipment(
        type: DeliveryType.pickup,
        status: ShipmentStatus.delivered,
        postalCode: postalCode,
      ),
    );

void main() {
  group('HeatMapService.localityPrefix', () {
    test('valid 7-digit postal code returns 4-digit prefix', () {
      expect(HeatMapService.localityPrefix('3000-550'), '3000');
    });

    test('null returns null', () {
      expect(HeatMapService.localityPrefix(null), isNull);
    });

    test('non-Portuguese format returns null', () {
      expect(HeatMapService.localityPrefix('75001'), isNull);
    });

    test('whitespace is trimmed before matching', () {
      expect(HeatMapService.localityPrefix(' 3000-550 '), '3000');
    });
  });

  group('HeatMapService.postalCounts — prefix extraction', () {
    test('valid 7-digit postal code maps to 4-digit prefix', () {
      final counts = HeatMapService.postalCounts([_shippingSale('3000-550')]);
      expect(counts, {'3000': 1});
    });

    test('two sales with the same prefix are counted together', () {
      final counts = HeatMapService.postalCounts([
        _shippingSale('1200-001'),
        _shippingSale('1200-999'),
      ]);
      expect(counts, {'1200': 2});
    });

    test('two different prefixes produce separate entries', () {
      final counts = HeatMapService.postalCounts([
        _shippingSale('1100-100'),
        _shippingSale('4700-200'),
      ]);
      expect(counts.length, 2);
      expect(counts['1100'], 1);
      expect(counts['4700'], 1);
    });
  });

  group('HeatMapService.postalCounts — postal code exclusions', () {
    test('null postal code is excluded', () {
      final counts = HeatMapService.postalCounts([_shippingSale(null)]);
      expect(counts, isEmpty);
    });

    test('non-Portuguese format (no dash) is excluded', () {
      final counts = HeatMapService.postalCounts([_shippingSale('12345')]);
      expect(counts, isEmpty);
    });

    test('wrong separator format is excluded', () {
      final counts = HeatMapService.postalCounts([_shippingSale('1200 001')]);
      expect(counts, isEmpty);
    });

    test('fewer than 4 digits before dash is excluded', () {
      final counts = HeatMapService.postalCounts([_shippingSale('120-001')]);
      expect(counts, isEmpty);
    });
  });

  group('HeatMapService.postalCounts — delivery type filter', () {
    test('shipping delivery type is included', () {
      final counts = HeatMapService.postalCounts([_shippingSale('1000-001')]);
      expect(counts, {'1000': 1});
    });

    test('handDelivery type is included', () {
      final counts = HeatMapService.postalCounts([_handDeliverySale('2000-001')]);
      expect(counts, {'2000': 1});
    });

    test('pickup delivery type is excluded', () {
      final counts = HeatMapService.postalCounts([_pickupSale('3000-001')]);
      expect(counts, isEmpty);
    });
  });

  group('HeatMapService.postalCounts — empty input', () {
    test('empty list returns empty map', () {
      expect(HeatMapService.postalCounts([]), isEmpty);
    });
  });
}
