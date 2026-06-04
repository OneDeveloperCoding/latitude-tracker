import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/repairs_store.dart';
import '../../../core/store/sales_store.dart';
import '../../../core/store/store_state.dart';
import '../../repairs/models/repair.dart';
import '../../sales/models/sale.dart';
import '../models/dashboard_stats.dart';
import '../widgets/analytics_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  final DashboardPeriod initialPeriod;
  final bool startOnRepairs;

  const AnalyticsScreen({
    super.key,
    required this.initialPeriod,
    this.startOnRepairs = false,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late DashboardPeriod _period;
  int _year = DateTime.now().year;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _weekStart = _mondayOf(DateTime.now());
  AnalyticsMetric _metric = AnalyticsMetric.revenue;
  late final TabController _tabController;

  static DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startOnRepairs ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _periodStart => switch (_period) {
        DashboardPeriod.yearly => DateTime(_year),
        DashboardPeriod.monthly => _month,
        DashboardPeriod.weekly => _weekStart,
      };

  DateTime get _periodEnd => switch (_period) {
        DashboardPeriod.yearly => DateTime(_year + 1),
        DashboardPeriod.monthly => DateTime(_month.year, _month.month + 1),
        DashboardPeriod.weekly => _weekStart.add(const Duration(days: 7)),
      };

  bool get _isCurrentPeriod {
    final now = DateTime.now();
    return switch (_period) {
      DashboardPeriod.yearly => _year == now.year,
      DashboardPeriod.monthly =>
        _month.year == now.year && _month.month == now.month,
      DashboardPeriod.weekly => _weekStart == _mondayOf(now),
    };
  }

  void _previous() => setState(() {
        switch (_period) {
          case DashboardPeriod.yearly:
            _year--;
          case DashboardPeriod.monthly:
            _month = DateTime(_month.year, _month.month - 1);
          case DashboardPeriod.weekly:
            _weekStart = _weekStart.subtract(const Duration(days: 7));
        }
      });

  void _next() {
    if (_isCurrentPeriod) return;
    setState(() {
      switch (_period) {
        case DashboardPeriod.yearly:
          _year++;
        case DashboardPeriod.monthly:
          _month = DateTime(_month.year, _month.month + 1);
        case DashboardPeriod.weekly:
          _weekStart = _weekStart.add(const Duration(days: 7));
      }
    });
  }

  String get _periodLabel => switch (_period) {
        DashboardPeriod.yearly => '$_year',
        DashboardPeriod.monthly => DateFormat('MMMM yyyy').format(_month),
        DashboardPeriod.weekly => () {
            final end = _weekStart.add(const Duration(days: 6));
            return '${DateFormat('d MMM').format(_weekStart)} – ${DateFormat('d MMM yyyy').format(end)}';
          }(),
      };

  (DateTime, DateTime) _shiftPeriod(int delta) => switch (_period) {
        DashboardPeriod.yearly => (
            DateTime(_year + delta),
            DateTime(_year + delta + 1),
          ),
        DashboardPeriod.monthly => (
            DateTime(_month.year, _month.month + delta),
            DateTime(_month.year, _month.month + delta + 1),
          ),
        DashboardPeriod.weekly => (
            _weekStart.add(Duration(days: 7 * delta)),
            _weekStart.add(Duration(days: 7 * (delta + 1))),
          ),
      };

  List<int> get _comparisonShifts => switch (_period) {
        DashboardPeriod.weekly => [-1, -4, -52],
        DashboardPeriod.monthly => [-1, -3, -6, -12],
        DashboardPeriod.yearly => [-1, -3, -5],
      };

  List<String> _sparklineLabels() {
    const periodCount = 6;
    return List.generate(periodCount, (i) {
      final offset = i - (periodCount - 1);
      return switch (_period) {
        DashboardPeriod.yearly => '\'${(_year + offset) % 100}',
        DashboardPeriod.monthly =>
          DateFormat('MMM')
              .format(DateTime(_month.year, _month.month + offset)),
        DashboardPeriod.weekly =>
          DateFormat('d/M').format(_weekStart.add(Duration(days: 7 * offset))),
      };
    });
  }

  List<List<({String category, double revenue})>> _computeStackedSparkline(
      List<Sale> all) {
    const periodCount = 6;
    return List.generate(periodCount, (i) {
      final offset = i - (periodCount - 1);
      final (start, end) = _shiftPeriod(offset);
      return DashboardStats.computeCategoryBreakdown(all, start, end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.trendsTitle),
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
              ButtonSegment(
                value: DashboardPeriod.weekly,
                icon: const Icon(Icons.calendar_view_week, size: 18),
                tooltip: s.tooltipWeek,
              ),
            ],
            selected: {_period},
            onSelectionChanged: (v) => setState(() => _period = v.first),
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.analyticsSalesTab),
            Tab(text: s.analyticsRepairsTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalesTab(context, s),
          _buildRepairsTab(context, s),
        ],
      ),
    );
  }

  Widget _buildSalesTab(BuildContext context, AppStrings s) {
    return ValueListenableBuilder<StoreState<List<Sale>>>(
        valueListenable: SalesStore.state,
        builder: (context, storeState, _) {
          if (storeState is StoreError<List<Sale>>) {
            return Center(child: Text(context.s.errorLoadingSales));
          }
          if (storeState is! StoreLoaded<List<Sale>>) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = storeState.data;
          final currentStats = DashboardStats.computePeriodStats(
              all, _periodStart, _periodEnd);
          final (prevStart, prevEnd) = _shiftPeriod(-1);
          final prevStats =
              DashboardStats.computePeriodStats(all, prevStart, prevEnd);
          final stackedSparkline = _computeStackedSparkline(all);
          final paymentBreakdown = DashboardStats.computePaymentMethodBreakdown(
              all, _periodStart, _periodEnd);
          final categoryBreakdown = DashboardStats.computeCategoryBreakdown(
              all, _periodStart, _periodEnd);
          final shifts = _comparisonShifts;
          final labels = s.trendComparisonLabels(_period);
          final hasStackedData =
              stackedSparkline.any((period) => period.isNotEmpty);

          return ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            children: [
              AnalyticsPeriodHeader(
                label: _periodLabel,
                onPrevious: _previous,
                onNext: _isCurrentPeriod ? null : _next,
              ),
              const SizedBox(height: 12),
              AnalyticsMetricToggle(
                metric: _metric,
                onChanged: (m) => setState(() => _metric = m),
              ),
              const SizedBox(height: 16),
              AnalyticsRevenueSummaryCard(
                currentStats: currentStats,
                prevStats: prevStats,
                metric: _metric,
              ),
              if (hasStackedData) ...[
                const SizedBox(height: 16),
                AnalyticsStackedBarChart(
                  periodsData: stackedSparkline,
                  periodLabels: _sparklineLabels(),
                ),
              ],
              const SizedBox(height: 8),
              ...List.generate(shifts.length, (i) {
                final (cmpStart, cmpEnd) = _shiftPeriod(shifts[i]);
                final cmpStats = DashboardStats.computePeriodStats(
                    all, cmpStart, cmpEnd);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AnalyticsComparisonRow(
                    label: labels[i],
                    currentStats: currentStats,
                    comparisonStats: cmpStats,
                    metric: _metric,
                  ),
                );
              }),
              if (categoryBreakdown.isNotEmpty) ...[
                const SizedBox(height: 8),
                AnalyticsTopCategoriesSection(breakdown: categoryBreakdown),
              ],
              if (paymentBreakdown.isNotEmpty) ...[
                const SizedBox(height: 8),
                AnalyticsPaymentMethodSection(breakdown: paymentBreakdown),
              ],
            ],
          );
        },
      );
  }

  Widget _buildRepairsTab(BuildContext context, AppStrings s) {
    return ValueListenableBuilder<StoreState<List<Repair>>>(
      valueListenable: RepairsStore.state,
      builder: (context, storeState, _) {
        if (storeState is StoreError<List<Repair>>) {
          return Center(child: Text(context.s.errorLoadingSales));
        }
        if (storeState is! StoreLoaded<List<Repair>>) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = storeState.data;
        final current = all
            .where((r) =>
                r.createdAt.isAfter(_periodStart) &&
                r.createdAt.isBefore(_periodEnd))
            .toList();

        if (current.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnalyticsPeriodHeader(
                  label: _periodLabel,
                  onPrevious: _previous,
                  onNext: _isCurrentPeriod ? null : _next,
                ),
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
            AnalyticsPeriodHeader(
              label: _periodLabel,
              onPrevious: _previous,
              onNext: _isCurrentPeriod ? null : _next,
            ),
            const SizedBox(height: 16),
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
      },
    );
  }
}
