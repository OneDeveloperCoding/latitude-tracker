import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/store/sales_store.dart';
import '../../../core/store/store_state.dart';
import '../../buyers/screens/unpaid_balances_screen.dart';
import '../../sales/models/sale.dart';
import '../../sales/models/sale_filter.dart';
import '../../sales/screens/nif_pending_screen.dart';
import '../../sales/screens/sales_list_screen.dart';
import '../../sales/screens/shopping_list_screen.dart';
import '../models/dashboard_stats.dart';
import 'trends_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardPeriod _period = DashboardPeriod.monthly;

  int _year = DateTime.now().year;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _weekStart = _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

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

  (DateTime, DateTime) _shiftedPeriod(int delta) => switch (_period) {
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

  List<double> _computeSparkline(List<Sale> all) {
    const periodCount = 6;
    return List.generate(periodCount, (i) {
      final offset = i - (periodCount - 1); // -5 … 0, current period last
      final (start, end) = _shiftedPeriod(offset);
      double revenue = 0;
      for (final s in all) {
        if (s.payment.status == PaymentStatus.paid &&
            !s.createdAt.isBefore(start) &&
            s.createdAt.isBefore(end)) {
          revenue += s.totalPrice;
        }
      }
      return revenue;
    });
  }

  List<String> _sparklineLabels() {
    const periodCount = 6;
    return List.generate(periodCount, (i) {
      final offset = i - (periodCount - 1);
      return switch (_period) {
        DashboardPeriod.yearly => '\'${(_year + offset) % 100}',
        DashboardPeriod.monthly =>
          DateFormat('MMM').format(DateTime(_month.year, _month.month + offset)),
        DashboardPeriod.weekly =>
          DateFormat('d/M').format(_weekStart.add(Duration(days: 7 * offset))),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.dashboard),
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
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
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
          final stats = DashboardStats.compute(all, _periodStart, _periodEnd);
          final sparkline = _computeSparkline(all);
          final topCategories = DashboardStats.computeTopCategories(
              all, _periodStart, _periodEnd);

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
              _RevenueCard(stats: stats, periodLabel: _periodLabel),
              const SizedBox(height: 24),
              Text(
                s.actionNeeded,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              _ActionGrid(stats: stats),
              const SizedBox(height: 24),
              _InsightsCard(
                stats: stats,
                sparkline: sparkline,
                sparklineLabels: _sparklineLabels(),
                topCategories: topCategories,
              ),
              const SizedBox(height: 8),
              _TrendsEntryCard(period: _period),
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

class _RevenueCard extends StatelessWidget {
  final DashboardStats stats;
  final String periodLabel;

  const _RevenueCard({required this.stats, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

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
              currencyFormat.format(stats.paidRevenue),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              s.nSales(stats.paidCount),
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

class _ActionGrid extends StatelessWidget {
  final DashboardStats stats;

  const _ActionGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, s.dashboardGroupMoney),
        _ButtonRow(buttons: [
          _ActionButton(
            icon: Icons.schedule,
            label: s.overdue,
            count: stats.overdueCount,
            color: Colors.red,
            destination: const SalesListScreen(
                initialFilters: {SaleFilter.overdue}),
          ),
          _ActionButton(
            icon: Icons.euro,
            label: s.unpaid,
            count: stats.unpaidActionCount,
            color: Colors.orange,
            amountLabel: stats.unpaidActionCount > 0
                ? currency.format(stats.unpaidActionRevenue)
                : null,
            destination: const UnpaidBalancesScreen(),
          ),
          _ActionButton(
            icon: kNifIcon,
            label: s.nifRequired,
            count: stats.nifRequiredCount,
            color: Colors.teal,
            destination: const NifPendingScreen(),
          ),
        ]),
        const SizedBox(height: 8),
        _sectionLabel(context, s.dashboardGroupProduction),
        _ButtonRow(buttons: [
          _ActionButton(
            icon: Icons.shopping_cart,
            label: s.assemblyNotReady,
            count: stats.assemblyNotReadyCount,
            color: Colors.purple,
            destination: const ShoppingListScreen(),
          ),
          _ActionButton(
            icon: Icons.local_shipping,
            label: s.pendingShipment,
            count: stats.pendingShipmentCount,
            color: Colors.blue,
            destination: const SalesListScreen(
                initialFilters: {SaleFilter.pendingShipment}),
          ),
          _ActionButton(
            icon: Icons.markunread_mailbox,
            label: s.inTransit,
            count: stats.shippedCount,
            color: Colors.indigo,
            destination: const SalesListScreen(
                initialFilters: {SaleFilter.shipped}),
          ),
        ]),
        const SizedBox(height: 8),
        _sectionLabel(context, s.dashboardGroupPlanning),
        _UpcomingButton(
          count: stats.upcomingCount,
          label: s.upcomingScheduled,
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                letterSpacing: 0.8,
              ),
        ),
      );
}

class _ButtonRow extends StatelessWidget {
  final List<Widget> buttons;

  const _ButtonRow({required this.buttons});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            Expanded(child: buttons[i]),
            if (i < buttons.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Widget destination;
  final String? amountLabel;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.destination,
    this.amountLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = count > 0;
    final effectiveColor = isActive ? color : Colors.grey;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => destination),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: effectiveColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: effectiveColor, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: effectiveColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isActive
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (amountLabel != null)
                    Text(
                      amountLabel!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: effectiveColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingButton extends StatelessWidget {
  final int count;
  final String label;

  const _UpcomingButton({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final isActive = count > 0;
    final color = isActive ? Colors.green : Colors.grey;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SalesListScreen(
                      initialFilters: {SaleFilter.upcomingScheduled},
                    ),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.event, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isActive
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.grey,
                      ),
                ),
              ),
              Text(
                '$count',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsCard extends StatefulWidget {
  final DashboardStats stats;
  final List<double> sparkline;
  final List<String> sparklineLabels;
  final List<({String category, double revenue})> topCategories;

  const _InsightsCard({
    required this.stats,
    required this.sparkline,
    required this.sparklineLabels,
    required this.topCategories,
  });

  @override
  State<_InsightsCard> createState() => _InsightsCardState();
}

class _InsightsCardState extends State<_InsightsCard> {
  bool _showValues = false;

  @override
  void didUpdateWidget(_InsightsCard old) {
    super.didUpdateWidget(old);
    // Reset when sparkline data changes (period navigation or Firestore update).
    if (!_sparklineEqual(old.sparkline, widget.sparkline)) {
      _showValues = false;
    }
  }

  static bool _sparklineEqual(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final colorScheme = Theme.of(context).colorScheme;

    final current = widget.sparkline.isNotEmpty ? widget.sparkline.last : 0.0;
    final prev = widget.sparkline.length >= 2
        ? widget.sparkline[widget.sparkline.length - 2]
        : 0.0;
    final hasTrend = prev > 0;
    final trendPct = hasTrend ? (current - prev) / prev * 100 : 0.0;
    final trendUp = trendPct >= 0;
    final maxCategoryRevenue = widget.topCategories.isNotEmpty
        ? widget.topCategories.first.revenue
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.dashboardTrends,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                ),
                const Spacer(),
                if (hasTrend) _TrendBadge(pct: trendPct.abs(), up: trendUp),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _StatChip(
                  icon: Icons.receipt_long,
                  label: s.nSales(widget.stats.totalCount),
                ),
                if (widget.stats.avgOrderValue > 0)
                  _StatChip(
                    icon: Icons.show_chart,
                    label:
                        '${s.avgOrderMetric} ${currency.format(widget.stats.avgOrderValue)}',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _showValues = !_showValues),
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SparklinePainter(
                        data: widget.sparkline,
                        color: colorScheme.primary,
                        allHighlighted: _showValues,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      widget.sparklineLabels.length,
                      (i) => Expanded(
                        child: Text(
                          widget.sparklineLabels[i],
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontSize: 10,
                                color: i == widget.sparklineLabels.length - 1
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                        ),
                      ),
                    ),
                  ),
                  if (_showValues) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        widget.sparkline.length,
                        (i) => Expanded(
                          child: Text(
                            '€${widget.sparkline[i].toStringAsFixed(0)}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontSize: 10,
                                  color: i == widget.sparkline.length - 1
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.topCategories.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Text(
                s.dashboardTopCategories.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                      letterSpacing: 0.8,
                    ),
              ),
              const SizedBox(height: 10),
              ...widget.topCategories.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryRow(
                      category: cat.category,
                      fraction: maxCategoryRevenue > 0
                          ? cat.revenue / maxCategoryRevenue
                          : 0,
                      revenueLabel: currency.format(cat.revenue),
                    ),
                  )),
            ],
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
    final color =
        up ? Colors.green : Theme.of(context).colorScheme.error;
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final double fraction;
  final String revenueLabel;

  const _CategoryRow({
    required this.category,
    required this.fraction,
    required this.revenueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              revenueLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                  Container(
                    color: colorScheme.outlineVariant,
                    width: constraints.maxWidth,
                  ),
                  Container(
                    color: colorScheme.primary,
                    width: constraints.maxWidth * fraction,
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

class _TrendsEntryCard extends StatelessWidget {
  final DashboardPeriod period;

  const _TrendsEntryCard({required this.period});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TrendsScreen(initialPeriod: period)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.insights, color: colorScheme.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  s.dashboardViewTrends,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.outline, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool allHighlighted;

  const _SparklinePainter({
    required this.data,
    required this.color,
    this.allHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce(math.max);
    if (maxVal == 0) return;

    final barWidth = size.width / data.length;
    const gap = 4.0;

    for (int i = 0; i < data.length; i++) {
      final isHighlighted = allHighlighted || i == data.length - 1;
      final barH = (data[i] / maxVal) * size.height;
      final rect = Rect.fromLTWH(
        i * barWidth + gap / 2,
        size.height - barH,
        barWidth - gap,
        barH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..color = color.withAlpha(isHighlighted ? 255 : 60)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.color != color || old.allHighlighted != allHighlighted;
}
