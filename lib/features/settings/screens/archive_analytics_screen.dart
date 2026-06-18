import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/features/dashboard/models/dashboard_stats.dart';
import 'package:latitude_tracker/features/dashboard/widgets/analytics_widgets.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sales_analytics_service.dart';

class ArchiveAnalyticsScreen extends StatefulWidget {

  const ArchiveAnalyticsScreen({required this.archive, super.key});
  final Map<String, dynamic> archive;

  @override
  State<ArchiveAnalyticsScreen> createState() =>
      _ArchiveAnalyticsScreenState();
}

class _ArchiveAnalyticsScreenState extends State<ArchiveAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final List<Sale> _sales;
  late final List<Repair> _repairs;
  late final int _year;
  late final bool _hasRepairs;
  late final TabController _tabController;
  // Year-level data never changes — computed once in initState.
  late final List<List<({String category, double revenue})>> _monthlyChart;
  late final List<String> _monthLabels;

  DashboardPeriod _period = DashboardPeriod.yearly;
  late DateTime _month;
  AnalyticsMetric _metric = AnalyticsMetric.revenue;

  // Period-scoped cache — updated by _rebuildPeriodCache() whenever
  // _period or _month changes. Metric changes skip the recompute.
  late ({double revenue, int count}) _currentStats;
  late Map<PaymentMethod, ({double revenue, int count})> _paymentBreakdown;
  late List<({String category, double revenue})> _categoryBreakdown;
  // Previous-period stats: zeros for yearly (no prior year in archive),
  // previous month's paid stats otherwise.
  late ({double revenue, int count}) _prevStats;

  @override
  void initState() {
    super.initState();
    _year = widget.archive['year'] as int;
    _month = DateTime(_year, 12);
    _sales = (widget.archive['sales'] as List<dynamic>? ?? [])
        .map((e) => Sale.fromArchiveMap(e as Map<String, dynamic>))
        .toList();
    _repairs = (widget.archive['repairs'] as List<dynamic>? ?? [])
        .map((e) => Repair.fromArchiveMap(e as Map<String, dynamic>))
        .toList();
    _hasRepairs = _repairs.isNotEmpty;
    _tabController = TabController(length: _hasRepairs ? 2 : 1, vsync: this);
    _monthlyChart = List.generate(12, (i) {
      final start = DateTime(_year, i + 1);
      final end = DateTime(_year, i + 2);
      return SalesAnalyticsService.computeCategoryBreakdown(_sales, start, end);
    });
    _monthLabels =
        List.generate(12, (i) => DateFormat('MMM').format(DateTime(_year, i + 1)));
    _rebuildPeriodCache();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _periodStart => _period == DashboardPeriod.monthly
      ? DateTime(_year, _month.month)
      : DateTime(_year);

  DateTime get _periodEnd => _period == DashboardPeriod.monthly
      ? DateTime(_year, _month.month + 1)
      : DateTime(_year + 1);

  void _rebuildPeriodCache() {
    _currentStats =
        SalesAnalyticsService.computePeriodStats(_sales, _periodStart, _periodEnd);
    _paymentBreakdown = SalesAnalyticsService.computePaymentMethodBreakdown(
        _sales, _periodStart, _periodEnd);
    _categoryBreakdown =
        SalesAnalyticsService.computeCategoryBreakdown(_sales, _periodStart, _periodEnd);
    _prevStats = _period == DashboardPeriod.monthly && _month.month > 1
        ? SalesAnalyticsService.computePeriodStats(
            _sales,
            DateTime(_year, _month.month - 1),
            DateTime(_year, _month.month),
          )
        : (revenue: 0.0, count: 0);
  }

  void _previous() {
    if (_period == DashboardPeriod.monthly && _month.month > 1) {
      _month = DateTime(_year, _month.month - 1);
      _rebuildPeriodCache();
      setState(() {});
    }
  }

  void _next() {
    if (_period == DashboardPeriod.monthly && _month.month < 12) {
      _month = DateTime(_year, _month.month + 1);
      _rebuildPeriodCache();
      setState(() {});
    }
  }

  String get _periodLabel => _period == DashboardPeriod.monthly
      ? DateFormat('MMMM yyyy').format(_month)
      : '$_year';

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text('${s.trendsTitle} $_year'),
        actions: [
          SegmentedButton<DashboardPeriod>(
            segments: [
              ButtonSegment(
                value: DashboardPeriod.yearly,
                icon: const Icon(Icons.calendar_today, size: 18),
                tooltip: s.tooltipYear,
              ),
              ButtonSegment(
                value: DashboardPeriod.monthly,
                icon: const Icon(Icons.calendar_month, size: 18),
                tooltip: s.tooltipMonth,
              ),
            ],
            selected: {_period},
            onSelectionChanged: (v) {
              _period = v.first;
              _rebuildPeriodCache();
              setState(() {});
            },
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(width: 8),
        ],
        bottom: _hasRepairs
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: s.analyticsSalesTab),
                  Tab(text: s.analyticsRepairsTab),
                ],
              )
            : null,
      ),
      body: _hasRepairs
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(context, s),
                _buildRepairsTab(context, s),
              ],
            )
          : _buildSalesTab(context, s),
    );
  }

  Widget _buildSalesTab(BuildContext context, AppStrings s) {
    if (_period == DashboardPeriod.yearly) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        children: [
          // No prior year in archive — prevStats zeros suppress the trend badge.
          AnalyticsRevenueSummaryCard(
            currentStats: _currentStats,
            prevStats: _prevStats,
            metric: _metric,
          ),
          if (_categoryBreakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            AnalyticsTopCategoriesSection(breakdown: _categoryBreakdown),
          ],
          if (_paymentBreakdown.isNotEmpty) ...[
            const SizedBox(height: 8),
            AnalyticsPaymentMethodSection(breakdown: _paymentBreakdown),
          ],
        ],
      );
    }

    // Monthly view.
    final hasChartData = _monthlyChart.any((p) => p.isNotEmpty);

    return ListView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      children: [
        AnalyticsPeriodHeader(
          label: _periodLabel,
          onPrevious: _month.month > 1 ? _previous : null,
          onNext: _month.month < 12 ? _next : null,
        ),
        const SizedBox(height: 12),
        AnalyticsMetricToggle(
          metric: _metric,
          onChanged: (m) => setState(() => _metric = m),
        ),
        const SizedBox(height: 16),
        AnalyticsRevenueSummaryCard(
          currentStats: _currentStats,
          prevStats: _prevStats,
          metric: _metric,
        ),
        if (hasChartData) ...[
          const SizedBox(height: 16),
          AnalyticsStackedBarChart(
            periodsData: _monthlyChart,
            periodLabels: _monthLabels,
          ),
        ],
        if (_categoryBreakdown.isNotEmpty) ...[
          const SizedBox(height: 8),
          AnalyticsTopCategoriesSection(breakdown: _categoryBreakdown),
        ],
        if (_paymentBreakdown.isNotEmpty) ...[
          const SizedBox(height: 8),
          AnalyticsPaymentMethodSection(breakdown: _paymentBreakdown),
        ],
      ],
    );
  }

  AnalyticsPeriodHeader? _repairsPeriodHeader() =>
      _period == DashboardPeriod.monthly
          ? AnalyticsPeriodHeader(
              label: _periodLabel,
              onPrevious: _month.month > 1 ? _previous : null,
              onNext: _month.month < 12 ? _next : null,
            )
          : null;

  Widget _buildRepairsTab(BuildContext context, AppStrings s) {
    final current = _repairs
        .where((r) =>
            !r.createdAt.isBefore(_periodStart) &&
            r.createdAt.isBefore(_periodEnd))
        .toList();

    if (current.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?_repairsPeriodHeader(),
            const SizedBox(height: 24),
            Text(s.noRepairDataForPeriod),
          ],
        ),
      );
    }

    final totalRevenue = current.fold<double>(
      0,
      (sum, r) =>
          sum +
          (r.payment.status == PaymentStatus.paid
              ? (r.materialsCost ?? 0)
              : 0),
    );
    final statusCounts = <RepairStatus, int>{};
    for (final r in current) {
      statusCounts[r.status] = (statusCounts[r.status] ?? 0) + 1;
    }
    final categoryCounts = <String, int>{};
    for (final r in current) {
      categoryCounts[r.itemCategory] =
          (categoryCounts[r.itemCategory] ?? 0) + 1;
    }
    final topCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      children: [
        ?_repairsPeriodHeader(),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.repairRevenue,
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  '€${totalRevenue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text('${current.length} ${s.repairCount.toLowerCase()}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.repairStatusByCount,
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                ...RepairStatus.values.map((st) {
                  final count = statusCounts[st] ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(s.repairStatusLabelFor(st))),
                        Text('$count'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        if (topCategories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.repairTopCategories,
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  ...topCategories.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(e.key)),
                            Text('${e.value}'),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
