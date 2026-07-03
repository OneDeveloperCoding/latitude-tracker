import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/features/buyers/repositories/buyer_repository.dart';
import 'package:latitude_tracker/features/dashboard/widgets/analytics_widgets.dart';
import 'package:latitude_tracker/features/heat_map/services/geographic_sales_service.dart';
import 'package:latitude_tracker/features/heat_map/services/heat_map_service.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/screens/sales_list_screen.dart';
import 'package:latlong2/latlong.dart';

class GeographicSalesScreen extends StatefulWidget {
  const GeographicSalesScreen({super.key});

  @override
  State<GeographicSalesScreen> createState() => _GeographicSalesScreenState();
}

class _GeographicSalesScreenState extends State<GeographicSalesScreen> {
  bool _mapMode = false;
  bool _includeHandDelivery = true;
  AnalyticsMetric _metric = AnalyticsMetric.revenue;

  List<int> _years = [];
  int? _selectedYear;

  // List view state
  GeoSalesRanking? _ranking;

  // Map view state
  List<HeatMapPoint> _mapPoints = [];

  bool _loading = true;
  String _status = '';

  // Incremented on every _load call; each future captures its own value and
  // only applies its result if the counter hasn't advanced (cancels stale
  // loads).
  int _loadGeneration = 0;

  late final NetworkTileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileProvider = NetworkTileProvider(
      cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: 50 * 1024 * 1024,
      ),
    );
    SalesStore.state.addListener(_onStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rebuild();
    });
  }

  @override
  void dispose() {
    SalesStore.state.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) _rebuild();
  }

  void _rebuild() {
    final all = _salesForView(SalesStore.currentOrEmpty);
    final years = all.map((s) => s.createdAt.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final year = (_selectedYear != null && years.contains(_selectedYear))
        ? _selectedYear
        : null;
    setState(() {
      _years = years;
      _selectedYear = year;
    });
    unawaited(_load(all, year));
  }

  Future<void> _load(List<Sale> sales, int? year) async {
    final generation = ++_loadGeneration;
    final filtered = year == null
        ? sales
        : sales.where((s) => s.createdAt.year == year).toList();

    setState(() {
      _loading = true;
      _status = context.s.locatingPostalCodes;
    });

    void applyIfCurrent(VoidCallback fn) {
      if (mounted && generation == _loadGeneration) fn();
    }

    try {
      if (_mapMode) {
        final points = await HeatMapService.buildPoints(filtered);
        applyIfCurrent(
          () => setState(() {
            _mapPoints = points;
            _loading = false;
          }),
        );
      } else {
        final addressCountries = await _fetchAddressCountries(filtered);
        if (generation != _loadGeneration) return;
        final ranking = await GeographicSalesService.buildRanking(
          filtered,
          addressCountries,
        );
        applyIfCurrent(
          () => setState(() {
            _ranking = ranking;
            _loading = false;
          }),
        );
      }
    } on Object catch (e, st) {
      logError(e, st);
      applyIfCurrent(() => setState(() => _loading = false));
    }
  }

  Future<Map<String, String>> _fetchAddressCountries(List<Sale> sales) async {
    final intlSales = sales.where((s) {
      final pc = s.shipment.postalCode;
      return pc != null &&
          pc.isNotEmpty &&
          HeatMapService.localityPrefix(pc) == null &&
          s.shipment.addressId != null;
    }).toList();

    if (intlSales.isEmpty) return {};

    final buyerIds = intlSales.map((s) => s.buyerId).toSet();
    final result = <String, String>{};
    final repo = BuyerRepository();

    for (final buyerId in buyerIds) {
      try {
        final addresses = await repo.watchAddresses(buyerId).first;
        for (final addr in addresses) {
          result[addr.id] = addr.country;
        }
      } on Object catch (_) {
        // Skip — that buyer's sales just won't appear in the international
        // section.
      }
    }

    return result;
  }

  void _selectYear(int? year) {
    if (year == _selectedYear) return;
    setState(() {
      _selectedYear = year;
      _ranking = null;
      _mapPoints = [];
    });
    unawaited(_load(_salesForView(SalesStore.currentOrEmpty), year));
  }

  void _toggleMode() {
    final newMapMode = !_mapMode;
    setState(() {
      _mapMode = newMapMode;
      _loading = true;
    });
    unawaited(_load(_salesForView(SalesStore.currentOrEmpty), _selectedYear));
  }

  void _toggleHandDelivery() {
    setState(() {
      _includeHandDelivery = !_includeHandDelivery;
      _ranking = null;
      _mapPoints = [];
    });
    unawaited(_load(_salesForView(SalesStore.currentOrEmpty), _selectedYear));
  }

  List<Sale> _salesForView(List<Sale> sales) => sales.where((s) {
    if (s.shipment.postalCode == null || s.shipment.postalCode!.isEmpty) {
      return false;
    }
    if (s.shipment.type == DeliveryType.shipping) return true;
    if (_includeHandDelivery && s.shipment.type == DeliveryType.handDelivery) {
      return true;
    }
    return false;
  }).toList();

  int _compareByMetric(
    double aRevenue,
    int aCount,
    double bRevenue,
    int bCount,
  ) => _metric == AnalyticsMetric.revenue
      ? bRevenue.compareTo(aRevenue)
      : bCount.compareTo(aCount);

  List<LocalityRow> get _sortedLocalities => (List<LocalityRow>.from(
    _ranking?.localities ?? [],
  ))..sort((a, b) => _compareByMetric(a.revenue, a.count, b.revenue, b.count));

  List<CountryRow> get _sortedCountries => (List<CountryRow>.from(
    _ranking?.countries ?? [],
  ))..sort((a, b) => _compareByMetric(a.revenue, a.count, b.revenue, b.count));

  double _markerSize(int count) =>
      (32 + (count - 1) * 8).clamp(32, 80).toDouble();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.geographicSalesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_walk),
            tooltip: s.handDelivery,
            isSelected: _includeHandDelivery,
            onPressed: _toggleHandDelivery,
          ),
          IconButton(
            icon: Icon(_mapMode ? Icons.list : Icons.map_outlined),
            tooltip: _mapMode ? s.geoSalesSwitchToList : s.geoSalesSwitchToMap,
            onPressed: _toggleMode,
          ),
        ],
        bottom: _years.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _YearFilterBar(
                  years: _years,
                  selected: _selectedYear,
                  allLabel: s.allYears,
                  onSelected: _selectYear,
                ),
              ),
      ),
      body: _mapMode ? _buildMap(s) : _buildList(s),
    );
  }

  Widget _buildMap(AppStrings s) {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(39.5, -8),
            initialZoom: 6.5,
            minZoom: 5,
            maxZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.latitude.tracker',
              tileProvider: _tileProvider,
              keepBuffer: 3,
              panBuffer: 2,
              tileDisplay: const TileDisplay.instantaneous(),
            ),
            MarkerLayer(
              markers: _mapPoints
                  .map(
                    (p) => Marker(
                      point: p.position,
                      width: _markerSize(p.count),
                      height: _markerSize(p.count),
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${p.locality} (${p.postalCode}) —'
                              ' ${s.nSales(p.count)}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        ),
                        child: _MapMarker(
                          count: p.count,
                          size: _markerSize(p.count),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        if (_loading) _LoadingOverlay(status: _status),
        if (!_loading && _mapPoints.isEmpty) _EmptyOverlay(s: s),
        if (!_loading && _mapPoints.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            child: _MapLegend(points: _mapPoints, s: s),
          ),
      ],
    );
  }

  Widget _buildList(AppStrings s) {
    if (_loading) {
      return _LoadingOverlay(status: _status);
    }

    final localities = _sortedLocalities;
    final countries = _sortedCountries;

    if (localities.isEmpty && countries.isEmpty) {
      return _EmptyOverlay(s: s);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AnalyticsMetricToggle(
            metric: _metric,
            onChanged: (m) => setState(() => _metric = m),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (localities.isNotEmpty) ...[
                _SectionHeader(label: s.geoSalesPortugal),
                for (final (i, row) in localities.indexed)
                  _LocalityTile(
                    rank: i + 1,
                    row: row,
                    metric: _metric,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SalesListScreen(
                          postalCodePrefix: row.postalCode,
                          appBarTitle: '${row.locality} · ${row.postalCode}',
                        ),
                      ),
                    ),
                  ),
              ],
              if (countries.isNotEmpty) ...[
                if (localities.isNotEmpty) const Divider(height: 1),
                _SectionHeader(label: s.geoSalesInternational),
                for (final (i, row) in countries.indexed)
                  _CountryTile(rank: i + 1, row: row, metric: _metric),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared year filter bar
// ───────────────────────────────────────────────────

class _YearFilterBar extends StatelessWidget {
  const _YearFilterBar({
    required this.years,
    required this.selected,
    required this.allLabel,
    required this.onSelected,
  });
  final List<int> years;
  final int? selected;
  final String allLabel;
  final void Function(int?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _chip(context, label: allLabel, value: null),
          ...years.map((y) => _chip(context, label: '$y', value: y)),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required int? value,
  }) {
    final isSelected = value == selected;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(isSelected ? null : value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ─── List view widgets
// ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LocalityTile extends StatelessWidget {
  const _LocalityTile({
    required this.rank,
    required this.row,
    required this.metric,
    required this.onTap,
  });
  final int rank;
  final LocalityRow row;
  final AnalyticsMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: SizedBox(
        width: 28,
        child: Text(
          '$rank',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      title: Text(row.locality),
      subtitle: Text(row.postalCode),
      trailing: Text(
        metric == AnalyticsMetric.revenue
            ? NumberFormat.currency(
                symbol: '€',
                decimalDigits: 0,
              ).format(row.revenue)
            : context.s.nSales(row.count),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.rank,
    required this.row,
    required this.metric,
  });
  final int rank;
  final CountryRow row;
  final AnalyticsMetric metric;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: SizedBox(
        width: 28,
        child: Text(
          '$rank',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      title: Text(row.country),
      trailing: Text(
        metric == AnalyticsMetric.revenue
            ? NumberFormat.currency(
                symbol: '€',
                decimalDigits: 0,
              ).format(row.revenue)
            : context.s.nSales(row.count),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// ─── Map sub-mode widgets
// ─────────────────────────────────────────────────────

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.count, required this.size});
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(160),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.points, required this.s});
  final List<HeatMapPoint> points;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final total = points.fold(0, (sum, p) => sum + p.count);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.nPostalCodes(points.length),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              s.nSales(total),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared overlays
// ──────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(status, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOverlay extends StatelessWidget {
  const _EmptyOverlay({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(s.noShippedSalesWithPostalCode),
            ],
          ),
        ),
      ),
    );
  }
}
