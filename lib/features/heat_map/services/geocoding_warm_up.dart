import 'dart:async';

import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/core/store/store_state.dart';
import 'package:latitude_tracker/features/heat_map/services/geocoding_service.dart';
import 'package:latitude_tracker/features/heat_map/services/heat_map_service.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

/// Warms the geocoding cache whenever the sales data changes.
///
/// Attach once at app start (via MainNav) so that by the time the user
/// navigates to GeographicSalesView, all locality prefixes are already cached
/// and the screen opens instantly instead of spending 1 req/sec × N prefixes.
class GeocodingWarmUp {
  GeocodingWarmUp._();

  static void attach() =>
      SalesStore.state.addListener(_onStoreChanged);

  static void detach() =>
      SalesStore.state.removeListener(_onStoreChanged);

  static void _onStoreChanged() {
    final state = SalesStore.state.value;
    if (state is! StoreLoaded<List<Sale>>) return;
    final prefixes = state.data
        .map((s) => HeatMapService.localityPrefix(s.shipment.postalCode))
        .whereType<String>()
        .toSet();
    unawaited(GeocodingService.warmUp(prefixes));
  }
}
