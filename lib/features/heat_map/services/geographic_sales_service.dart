import 'package:latitude_tracker/features/buyers/models/buyer_address.dart';
import 'package:latitude_tracker/features/heat_map/services/cp4_coordinates_service.dart';
import 'package:latitude_tracker/features/heat_map/services/heat_map_service.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

class LocalityRow {
  const LocalityRow({
    required this.postalCode,
    required this.locality,
    required this.count,
    required this.revenue,
  });
  final String postalCode;
  final String locality;
  final int count;
  final double revenue;
}

class CountryRow {
  const CountryRow({
    required this.country,
    required this.count,
    required this.revenue,
  });
  final String country;
  final int count;
  final double revenue;
}

class GeoSalesRanking {
  const GeoSalesRanking({required this.localities, required this.countries});
  final List<LocalityRow> localities;
  final List<CountryRow> countries;

  bool get isEmpty => localities.isEmpty && countries.isEmpty;
}

class GeographicSalesService {
  GeographicSalesService._();

  /// Builds the ranked data for the list view.
  ///
  /// [addressCountries] maps shipment addressId → country for non-PT sales.
  /// Portugal rows get their locality name from the bundled CP4 table.
  static Future<GeoSalesRanking> buildRanking(
    List<Sale> sales,
    Map<String, String> addressCountries,
  ) async {
    final ptCounts = <String, int>{};
    final ptRevenue = <String, double>{};
    final intlCounts = <String, int>{};
    final intlRevenue = <String, double>{};

    for (final sale in sales) {
      final prefix = HeatMapService.localityPrefix(sale.shipment.postalCode);
      if (prefix != null) {
        ptCounts[prefix] = (ptCounts[prefix] ?? 0) + 1;
        ptRevenue[prefix] = (ptRevenue[prefix] ?? 0.0) + sale.totalPrice;
      } else {
        final addressId = sale.shipment.addressId;
        if (addressId == null) continue;
        final country = addressCountries[addressId];
        if (country == null ||
            country.toLowerCase() ==
                BuyerAddress.defaultCountry.toLowerCase()) {
          continue;
        }
        intlCounts[country] = (intlCounts[country] ?? 0) + 1;
        intlRevenue[country] = (intlRevenue[country] ?? 0.0) + sale.totalPrice;
      }
    }

    final localities = <LocalityRow>[];

    for (final entry in ptCounts.entries) {
      final result = await Cp4CoordinatesService.lookup(entry.key);
      localities.add(
        LocalityRow(
          postalCode: entry.key,
          locality: result?.locality ?? entry.key,
          count: entry.value,
          revenue: ptRevenue[entry.key] ?? 0.0,
        ),
      );
    }

    final countries = [
      for (final e in intlCounts.entries)
        CountryRow(
          country: e.key,
          count: e.value,
          revenue: intlRevenue[e.key] ?? 0.0,
        ),
    ];

    return GeoSalesRanking(localities: localities, countries: countries);
  }
}
