import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/sales_store.dart';
import '../../../core/store/store_state.dart';
import '../../sales/models/sale.dart';
import '../models/dashboard_stats.dart';

class TrendsScreen extends StatefulWidget {
  final DashboardPeriod initialPeriod;

  const TrendsScreen({super.key, required this.initialPeriod});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  late DashboardPeriod _period;
  int _year = DateTime.now().year;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _weekStart = _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
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
      ),
      body: ValueListenableBuilder<StoreState<List<Sale>>>(
        valueListenable: SalesStore.state,
        builder: (context, storeState, _) {
          if (storeState is! StoreLoaded<List<Sale>>) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = storeState.data;
          final currentStats =
              DashboardStats.computePeriodStats(all, _periodStart, _periodEnd);
          final shifts = _comparisonShifts;
          final labels = s.trendComparisonLabels(_period);

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
              _CurrentPeriodCard(
                stats: currentStats,
                periodLabel: _periodLabel,
              ),
              const SizedBox(height: 16),
              ...List.generate(shifts.length, (i) {
                final (cmpStart, cmpEnd) = _shiftPeriod(shifts[i]);
                final cmpStats =
                    DashboardStats.computePeriodStats(all, cmpStart, cmpEnd);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ComparisonRow(
                    label: labels[i],
                    currentRevenue: currentStats.revenue,
                    comparisonStats: cmpStats,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

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

class _CurrentPeriodCard extends StatelessWidget {
  final ({double revenue, int count}) stats;
  final String periodLabel;

  const _CurrentPeriodCard({
    required this.stats,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              periodLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              currency.format(stats.revenue),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              s.nSales(stats.count),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final double currentRevenue;
  final ({double revenue, int count}) comparisonStats;

  const _ComparisonRow({
    required this.label,
    required this.currentRevenue,
    required this.comparisonStats,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final colorScheme = Theme.of(context).colorScheme;

    final hasPrev = comparisonStats.revenue > 0;
    final delta = currentRevenue - comparisonStats.revenue;
    final pct =
        hasPrev ? delta / comparisonStats.revenue * 100 : null;
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
                currency.format(comparisonStats.revenue),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
              Text(
                s.nSales(comparisonStats.count),
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
