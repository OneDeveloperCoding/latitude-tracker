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

  static bool _attached = false;
  static bool _warming = false;

  /// Idempotent — safe to call multiple times (e.g. after a DemoMode
  /// transition where the old MainNav.dispose() removes the listener the new
  /// MainNav.initState() just added).
  static void attach() {
    if (_attached) return;
    _attached = true;
    SalesStore.state.addListener(_onStoreChanged);
  }

  static void detach() {
    if (!_attached) return;
    _attached = false;
    SalesStore.state.removeListener(_onStoreChanged);
  }

  static void _onStoreChanged() {
    final state = SalesStore.state.value;
    if (state is! StoreLoaded<List<Sale>>) return;
    final prefixes = state.data
        .map((s) => HeatMapService.localityPrefix(s.shipment.postalCode))
        .whereType<String>()
        .toSet();
    unawaited(_runWarmUp(prefixes));
  }

  // Skips if a warm-up is already in progress — prevents concurrent Nominatim
  // requests for the same uncached prefixes when store emits rapidly.
  static Future<void> _runWarmUp(Set<String> prefixes) async {
    if (_warming) return;
    _warming = true;
    try {
      await GeocodingService.warmUp(prefixes);
    } finally {
      _warming = false;
    }
  }
}
