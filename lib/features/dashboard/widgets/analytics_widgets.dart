import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/widgets/payment_method_display.dart';

enum AnalyticsMetric { revenue, count }

double _sumRevenue(Iterable<({String category, double revenue})> entries) =>
    entries.fold(0, (sum, e) => sum + e.revenue);

// Tableau 10 palette — designed for perceptual distinctiveness.
const kAnalyticsCategoryColors = [
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

Color analyticsColorForCategory(String category, List<String> ordered) {
  final i = ordered.indexOf(category);
  return i < 0
      ? Colors.grey
      : kAnalyticsCategoryColors[i % kAnalyticsCategoryColors.length];
}

// ─────────────────────────────────────────────────────────────────────────────
// Period header
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsPeriodHeader extends StatelessWidget {
  const AnalyticsPeriodHeader({
    required this.label,
    super.key,
    this.onPrevious,
    this.onNext,
  });
  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: onPrevious == null ? Theme.of(context).disabledColor : null,
          ),
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

class AnalyticsMetricToggle extends StatelessWidget {
  const AnalyticsMetricToggle({
    required this.metric,
    required this.onChanged,
    super.key,
  });
  final AnalyticsMetric metric;
  final ValueChanged<AnalyticsMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SegmentedButton<AnalyticsMetric>(
      segments: [
        ButtonSegment(
          value: AnalyticsMetric.revenue,
          label: Text(s.trendsMetricRevenue),
          icon: const Icon(Icons.euro, size: 16),
        ),
        ButtonSegment(
          value: AnalyticsMetric.count,
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

class AnalyticsRevenueSummaryCard extends StatelessWidget {
  const AnalyticsRevenueSummaryCard({
    required this.currentStats,
    required this.prevStats,
    required this.metric,
    super.key,
  });
  final ({double revenue, int count}) currentStats;
  final ({double revenue, int count}) prevStats;
  final AnalyticsMetric metric;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final colorScheme = Theme.of(context).colorScheme;

    final currentValue = metric == AnalyticsMetric.revenue
        ? currentStats.revenue
        : currentStats.count.toDouble();
    final prevValue = metric == AnalyticsMetric.revenue
        ? prevStats.revenue
        : prevStats.count.toDouble();
    final trendPct = prevValue > 0
        ? (currentValue - prevValue) / prevValue * 100
        : null;

    final primary = metric == AnalyticsMetric.revenue
        ? currency.format(currentStats.revenue)
        : '${currentStats.count}';
    final secondary = metric == AnalyticsMetric.revenue
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
                  if (metric == AnalyticsMetric.revenue && avgOrder != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 13,
                            color: colorScheme.onPrimaryContainer.withAlpha(
                              180,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${s.avgSaleMetric} ${currency.format(avgOrder)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
              AnalyticsTrendBadge(pct: trendPct.abs(), up: trendPct >= 0),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stacked category bar chart
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsStackedBarChart extends StatefulWidget {
  const AnalyticsStackedBarChart({
    required this.periodsData,
    required this.periodLabels,
    super.key,
  });
  final List<List<({String category, double revenue})>> periodsData;
  final List<String> periodLabels;

  @override
  State<AnalyticsStackedBarChart> createState() =>
      _AnalyticsStackedBarChartState();
}

class _AnalyticsStackedBarChartState extends State<AnalyticsStackedBarChart> {
  bool _showValues = false;
  final Set<String> _selectedCategories = {};

  @override
  void didUpdateWidget(AnalyticsStackedBarChart old) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final orderedCategories = _orderedCategories();

    final periodTotals = widget.periodsData.map(_sumRevenue).toList();

    final categoryValues = {
      for (final cat in orderedCategories)
        cat: widget.periodsData
            .map(
              (period) => _sumRevenue(period.where((e) => e.category == cat)),
            )
            .toList(),
    };

    final shownCategories = _selectedCategories.isEmpty
        ? orderedCategories
        : orderedCategories.where(_selectedCategories.contains).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.s.trendsRevenueByCategory.toUpperCase(),
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
                      painter: _AnalyticsStackedBarPainter(
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
                          style: Theme.of(context).textTheme.labelSmall
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
                            style: Theme.of(context).textTheme.labelSmall
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
                final color = analyticsColorForCategory(cat, orderedCategories);
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
                      horizontal: 10,
                      vertical: 5,
                    ),
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
                    final color = analyticsColorForCategory(
                      cat,
                      orderedCategories,
                    );
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

class _AnalyticsStackedBarPainter extends CustomPainter {
  const _AnalyticsStackedBarPainter({
    required this.periodsData,
    required this.orderedCategories,
    required this.selectedCategories,
    required this.allHighlighted,
  });
  final List<List<({String category, double revenue})>> periodsData;
  final List<String> orderedCategories;
  final Set<String> selectedCategories;
  final bool allHighlighted;

  @override
  void paint(Canvas canvas, Size size) {
    if (periodsData.isEmpty) return;

    var maxTotal = 0.0;
    for (final period in periodsData) {
      final total = _sumRevenue(period);
      if (total > maxTotal) maxTotal = total;
    }
    if (maxTotal == 0) return;

    final barWidth = size.width / periodsData.length;
    const gap = 4.0;
    final lastIndex = periodsData.length - 1;

    for (var i = 0; i < periodsData.length; i++) {
      final period = periodsData[i];
      if (period.isEmpty) continue;

      final periodAlpha = (allHighlighted || i == lastIndex) ? 1.0 : 0.4;
      final total = _sumRevenue(period);
      final totalBarH = (total / maxTotal) * size.height;
      final barLeft = i * barWidth + gap / 2;
      final barRight = (i + 1) * barWidth - gap / 2;

      canvas
        ..save()
        ..clipRRect(
          RRect.fromLTRBR(
            barLeft,
            size.height - totalBarH,
            barRight,
            size.height,
            const Radius.circular(3),
          ),
        );

      var bottomY = size.height;
      for (final e in period) {
        final categoryActive =
            selectedCategories.isEmpty ||
            selectedCategories.contains(e.category);
        final effectiveColor = categoryActive
            ? analyticsColorForCategory(
                e.category,
                orderedCategories,
              ).withAlpha((255 * periodAlpha).round())
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
  bool shouldRepaint(_AnalyticsStackedBarPainter old) =>
      old.periodsData != periodsData ||
      old.orderedCategories != orderedCategories ||
      old.selectedCategories != selectedCategories ||
      old.allHighlighted != allHighlighted;
}

// ─────────────────────────────────────────────────────────────────────────────
// Comparison rows
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsComparisonRow extends StatelessWidget {
  const AnalyticsComparisonRow({
    required this.label,
    required this.currentStats,
    required this.comparisonStats,
    required this.metric,
    super.key,
  });
  final String label;
  final ({double revenue, int count}) currentStats;
  final ({double revenue, int count}) comparisonStats;
  final AnalyticsMetric metric;

  double get _currentValue => metric == AnalyticsMetric.revenue
      ? currentStats.revenue
      : currentStats.count.toDouble();

  double get _comparisonValue => metric == AnalyticsMetric.revenue
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
                if (pct != null)
                  AnalyticsTrendBadge(pct: pct.abs(), up: trendUp),
              ],
            ),
            const SizedBox(height: 6),
            if (hasPrev) ...[
              Text(
                metric == AnalyticsMetric.revenue
                    ? currency.format(comparisonStats.revenue)
                    : '${comparisonStats.count}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                metric == AnalyticsMetric.revenue
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

class AnalyticsTrendBadge extends StatelessWidget {
  const AnalyticsTrendBadge({required this.pct, required this.up, super.key});
  final double pct;
  final bool up;

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

class AnalyticsPaymentMethodSection extends StatelessWidget {
  const AnalyticsPaymentMethodSection({required this.breakdown, super.key});
  final Map<PaymentMethod, ({double revenue, int count})> breakdown;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final colorScheme = Theme.of(context).colorScheme;

    final totalRevenue = breakdown.values.fold<double>(
      0,
      (sum, e) => sum + e.revenue,
    );
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
                child: AnalyticsBarRow(
                  label: entry.key.label,
                  sublabel:
                      '${currency.format(entry.value.revenue)} ·'
                      ' ${s.nSales(entry.value.count)}',
                  fraction: totalRevenue > 0
                      ? entry.value.revenue / totalRevenue
                      : 0,
                  barColor: paymentMethodColor(entry.key),
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

class AnalyticsTopCategoriesSection extends StatelessWidget {
  const AnalyticsTopCategoriesSection({required this.breakdown, super.key});
  final List<({String category, double revenue})> breakdown;

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
                child: AnalyticsBarRow(
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

class AnalyticsBarRow extends StatelessWidget {
  const AnalyticsBarRow({
    required this.label,
    required this.sublabel,
    required this.fraction,
    required this.barColor,
    required this.trackColor,
    super.key,
  });
  final String label;
  final String sublabel;
  final double fraction;
  final Color barColor;
  final Color trackColor;

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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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
                    width:
                        constraints.maxWidth *
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
