import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/repairs_store.dart';
import '../../../core/store/sales_store.dart';
import '../../../core/store/store_state.dart';
import '../../repairs/models/repair.dart';
import '../../sales/models/sale.dart';
import '../models/dashboard_stats.dart';

enum _AnalyticsMetric { revenue, count }

// Tableau 10 palette — designed for perceptual distinctiveness.
const _kCategoryColors = [
  Color(0xFF4E79A7),
  Color(0xFFF28E2B),
  Color(0xFFE15759),
  Color(0xFF76B7B2),
  Color(0xFF59A14F),
  Color(0xFFEDC948),
  Color(0xFFB07AA1),
  Color(0xFFFF9DA7),
  Color(0xFF9C755F),
  Color(0xFFBAB0AC),
];

Color _colorForCategory(String category, List<String> ordered) {
  final i = ordered.indexOf(category);
  return i < 0 ? Colors.grey : _kCategoryColors[i % _kCategoryColors.length];
}

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
  _AnalyticsMetric _metric = _AnalyticsMetric.revenue;
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
              _PeriodHeader(
                label: _periodLabel,
                onPrevious: _previous,
                onNext: _isCurrentPeriod ? null : _next,
              ),
              const SizedBox(height: 12),
              _MetricToggle(
                metric: _metric,
                onChanged: (m) => setState(() => _metric = m),
              ),
              const SizedBox(height: 16),
              _RevenueSummaryCard(
                currentStats: currentStats,
                prevStats: prevStats,
                metric: _metric,
              ),
              if (hasStackedData) ...[
                const SizedBox(height: 16),
                _StackedBarChart(
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
                  child: _ComparisonRow(
                    label: labels[i],
                    currentStats: currentStats,
                    comparisonStats: cmpStats,
                    metric: _metric,
                  ),
                );
              }),
              if (categoryBreakdown.isNotEmpty) ...[
                const SizedBox(height: 8),
                _TopCategoriesSection(breakdown: categoryBreakdown),
              ],
              if (paymentBreakdown.isNotEmpty) ...[
                const SizedBox(height: 8),
                _PaymentMethodSection(breakdown: paymentBreakdown),
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
                _PeriodHeader(
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
            _PeriodHeader(
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

// ─────────────────────────────────────────────────────────────────────────────
// Period header
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodHeader extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const _PeriodHeader({
    required this.label,
    required this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: onNext == null ? Theme.of(context).disabledColor : null,
          ),
          onPressed: onNext,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric toggle
// ─────────────────────────────────────────────────────────────────────────────

class _MetricToggle extends StatelessWidget {
  final _AnalyticsMetric metric;
  final ValueChanged<_AnalyticsMetric> onChanged;

  const _MetricToggle({required this.metric, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SegmentedButton<_AnalyticsMetric>(
      segments: [
        ButtonSegment(
          value: _AnalyticsMetric.revenue,
          label: Text(s.trendsMetricRevenue),
          icon: const Icon(Icons.euro, size: 16),
        ),
        ButtonSegment(
          value: _AnalyticsMetric.count,
          label: Text(s.trendsMetricCount),
          icon: const Icon(Icons.receipt_long, size: 16),
        ),
      ],
      selected: {metric},
      onSelectionChanged: (v) => onChanged(v.first),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Revenue summary card — paid total + avg order + trend badge
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueSummaryCard extends StatelessWidget {
  final ({double revenue, int count}) currentStats;
  final ({double revenue, int count}) prevStats;
  final _AnalyticsMetric metric;

  const _RevenueSummaryCard({
    required this.currentStats,
    required this.prevStats,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final colorScheme = Theme.of(context).colorScheme;

    final currentValue = metric == _AnalyticsMetric.revenue
        ? currentStats.revenue
        : currentStats.count.toDouble();
    final prevValue = metric == _AnalyticsMetric.revenue
        ? prevStats.revenue
        : prevStats.count.toDouble();
    final double? trendPct =
        prevValue > 0 ? (currentValue - prevValue) / prevValue * 100 : null;

    final primary = metric == _AnalyticsMetric.revenue
        ? currency.format(currentStats.revenue)
        : '${currentStats.count}';
    final secondary = metric == _AnalyticsMetric.revenue
        ? s.nSales(currentStats.count)
        : currency.format(currentStats.revenue);
    final avgOrder = currentStats.count > 0
        ? currentStats.revenue / currentStats.count
        : null;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    secondary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                  if (metric == _AnalyticsMetric.revenue && avgOrder != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 13,
                            color: colorScheme.onPrimaryContainer.withAlpha(180),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${s.avgOrderMetric} ${currency.format(avgOrder)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer
                                          .withAlpha(180),
                                    ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (trendPct != null) ...[
              const SizedBox(width: 12),
              _TrendBadge(pct: trendPct.abs(), up: trendPct >= 0),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stacked category bar chart (6 periods)
// ─────────────────────────────────────────────────────────────────────────────

class _StackedBarChart extends StatefulWidget {
  final List<List<({String category, double revenue})>> periodsData;
  final List<String> periodLabels;

  const _StackedBarChart({
    required this.periodsData,
    required this.periodLabels,
  });

  @override
  State<_StackedBarChart> createState() => _StackedBarChartState();
}

class _StackedBarChartState extends State<_StackedBarChart> {
  bool _showValues = false;
  final Set<String> _selectedCategories = {};

  @override
  void didUpdateWidget(_StackedBarChart old) {
    super.didUpdateWidget(old);
    // Reset when data changes (period navigation or store update).
    if (!_periodsEqual(old.periodsData, widget.periodsData)) {
      _showValues = false;
      _selectedCategories.clear();
    }
  }

  static bool _periodsEqual(
    List<List<({String category, double revenue})>> a,
    List<List<({String category, double revenue})>> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].length != b[i].length) return false;
      for (var j = 0; j < a[i].length; j++) {
        if (a[i][j].category != b[i][j].category ||
            a[i][j].revenue != b[i][j].revenue) {
          return false;
        }
      }
    }
    return true;
  }

  List<String> _orderedCategories() {
    final set = <String>{};
    for (final period in widget.periodsData) {
      for (final e in period) {
        set.add(e.category);
      }
    }
    return set.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;
    final orderedCategories = _orderedCategories();

    final periodTotals = widget.periodsData
        .map((p) => p.fold(0.0, (sum, e) => sum + e.revenue))
        .toList();

    final categoryValues = {
      for (final cat in orderedCategories)
        cat: widget.periodsData
            .map((period) => period
                .where((e) => e.category == cat)
                .fold(0.0, (sum, e) => sum + e.revenue))
            .toList(),
    };

    final shownCategories = _selectedCategories.isEmpty
        ? orderedCategories
        : orderedCategories
            .where((cat) => _selectedCategories.contains(cat))
            .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.trendsRevenueByCategory.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showValues = !_showValues),
              child: Column(
                children: [
                  SizedBox(
                    height: 64,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _StackedBarPainter(
                        periodsData: widget.periodsData,
                        orderedCategories: orderedCategories,
                        selectedCategories: _selectedCategories,
                        allHighlighted: _showValues,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      widget.periodLabels.length,
                      (i) => Expanded(
                        child: Text(
                          widget.periodLabels[i],
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontSize: 10,
                                color: i == widget.periodLabels.length - 1
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                        ),
                      ),
                    ),
                  ),
                  if (_showValues) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        periodTotals.length,
                        (i) => Expanded(
                          child: Text(
                            periodTotals[i] > 0
                                ? '€${periodTotals[i].toStringAsFixed(0)}'
                                : '—',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: i == periodTotals.length - 1
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_showValues && shownCategories.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...shownCategories.map((cat) {
                final color = _colorForCategory(cat, orderedCategories);
                final values = categoryValues[cat]!;
                final lastIndex = values.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withAlpha(22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    child: Row(
                      children: List.generate(
                        values.length,
                        (i) => Expanded(
                          child: Text(
                            values[i] > 0
                                ? '€${values[i].toStringAsFixed(0)}'
                                : '—',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: i == lastIndex
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: i == lastIndex
                                  ? color
                                  : color.withAlpha(140),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
            if (orderedCategories.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Multi-select chips — act as both legend and filter.
              // Empty selection means all categories shown/highlighted.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: orderedCategories.map((cat) {
                    final color = _colorForCategory(cat, orderedCategories);
                    final isSelected = _selectedCategories.contains(cat);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        backgroundColor: color.withAlpha(22),
                        selectedColor: color.withAlpha(50),
                        checkmarkColor: color,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedCategories.add(cat);
                          } else {
                            _selectedCategories.remove(cat);
                          }
                        }),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StackedBarPainter extends CustomPainter {
  final List<List<({String category, double revenue})>> periodsData;
  final List<String> orderedCategories;
  final Set<String> selectedCategories;
  final bool allHighlighted;

  const _StackedBarPainter({
    required this.periodsData,
    required this.orderedCategories,
    required this.selectedCategories,
    required this.allHighlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (periodsData.isEmpty) return;

    double maxTotal = 0;
    for (final period in periodsData) {
      final total = period.fold(0.0, (s, e) => s + e.revenue);
      if (total > maxTotal) maxTotal = total;
    }
    if (maxTotal == 0) return;

    final barWidth = size.width / periodsData.length;
    const gap = 4.0;
    final lastIndex = periodsData.length - 1;

    for (int i = 0; i < periodsData.length; i++) {
      final period = periodsData[i];
      if (period.isEmpty) continue;

      final periodAlpha = (allHighlighted || i == lastIndex) ? 1.0 : 0.4;
      final total = period.fold(0.0, (s, e) => s + e.revenue);
      final totalBarH = (total / maxTotal) * size.height;
      final barLeft = i * barWidth + gap / 2;
      final barRight = (i + 1) * barWidth - gap / 2;

      canvas.save();
      canvas.clipRRect(RRect.fromLTRBR(
        barLeft,
        size.height - totalBarH,
        barRight,
        size.height,
        const Radius.circular(3),
      ));

      double bottomY = size.height;
      for (final e in period) {
        final bool categoryActive = selectedCategories.isEmpty ||
            selectedCategories.contains(e.category);
        final Color effectiveColor = categoryActive
            ? _colorForCategory(e.category, orderedCategories)
                .withAlpha((255 * periodAlpha).round())
            : Colors.grey.withAlpha(35);
        final segH = (e.revenue / maxTotal) * size.height;
        canvas.drawRect(
          Rect.fromLTWH(barLeft, bottomY - segH, barRight - barLeft, segH),
          Paint()
            ..color = effectiveColor
            ..style = PaintingStyle.fill,
        );
        bottomY -= segH;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StackedBarPainter old) =>
      old.periodsData != periodsData ||
      old.orderedCategories != orderedCategories ||
      old.selectedCategories != selectedCategories ||
      old.allHighlighted != allHighlighted;
}

// ─────────────────────────────────────────────────────────────────────────────
// Comparison rows
// ─────────────────────────────────────────────────────────────────────────────

class _ComparisonRow extends StatelessWidget {
  final String label;
  final ({double revenue, int count}) currentStats;
  final ({double revenue, int count}) comparisonStats;
  final _AnalyticsMetric metric;

  const _ComparisonRow({
    required this.label,
    required this.currentStats,
    required this.comparisonStats,
    required this.metric,
  });

  double get _currentValue => metric == _AnalyticsMetric.revenue
      ? currentStats.revenue
      : currentStats.count.toDouble();

  double get _comparisonValue => metric == _AnalyticsMetric.revenue
      ? comparisonStats.revenue
      : comparisonStats.count.toDouble();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final colorScheme = Theme.of(context).colorScheme;

    final hasPrev = _comparisonValue > 0;
    final delta = _currentValue - _comparisonValue;
    final pct = hasPrev ? delta / _comparisonValue * 100 : null;
    final trendUp = pct != null && pct >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (pct != null) _TrendBadge(pct: pct.abs(), up: trendUp),
              ],
            ),
            const SizedBox(height: 6),
            if (hasPrev) ...[
              Text(
                metric == _AnalyticsMetric.revenue
                    ? currency.format(comparisonStats.revenue)
                    : '${comparisonStats.count}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
              Text(
                metric == _AnalyticsMetric.revenue
                    ? s.nSales(comparisonStats.count)
                    : currency.format(comparisonStats.revenue),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ] else
              Text(
                s.trendsNoPreviousData,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final double pct;
  final bool up;

  const _TrendBadge({required this.pct, required this.up});

  @override
  Widget build(BuildContext context) {
    final color = up ? Colors.green : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${up ? '↑' : '↓'} ${pct.toStringAsFixed(0)}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment method breakdown
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethodSection extends StatelessWidget {
  final Map<PaymentMethod, ({double revenue, int count})> breakdown;

  const _PaymentMethodSection({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final colorScheme = Theme.of(context).colorScheme;

    final totalRevenue =
        breakdown.values.fold(0.0, (sum, e) => sum + e.revenue);
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.trendsPaymentMethods.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 10),
            ...sorted.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BarRow(
                  label: entry.key.label,
                  sublabel:
                      '${currency.format(entry.value.revenue)} · ${s.nSales(entry.value.count)}',
                  fraction: totalRevenue > 0
                      ? entry.value.revenue / totalRevenue
                      : 0,
                  barColor: colorScheme.primary,
                  trackColor: colorScheme.outlineVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top categories section
// ─────────────────────────────────────────────────────────────────────────────

class _TopCategoriesSection extends StatelessWidget {
  final List<({String category, double revenue})> breakdown;

  const _TopCategoriesSection({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final colorScheme = Theme.of(context).colorScheme;
    final maxRevenue = breakdown.isNotEmpty ? breakdown.first.revenue : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.dashboardTopCategories.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 10),
            ...breakdown.map(
              (cat) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BarRow(
                  label: cat.category,
                  sublabel: currency.format(cat.revenue),
                  fraction: maxRevenue > 0 ? cat.revenue / maxRevenue : 0,
                  barColor: colorScheme.primary,
                  trackColor: colorScheme.outlineVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared labelled bar row (used by payment and category sections)
// ─────────────────────────────────────────────────────────────────────────────

class _BarRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final double fraction;
  final Color barColor;
  final Color trackColor;

  const _BarRow({
    required this.label,
    required this.sublabel,
    required this.fraction,
    required this.barColor,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              sublabel,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) => ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: trackColor, width: constraints.maxWidth),
                  Container(
                    color: barColor,
                    width: constraints.maxWidth *
                        math.max(0, math.min(1, fraction)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
