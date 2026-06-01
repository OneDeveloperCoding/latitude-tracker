import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../sales/models/sale.dart';
import '../../sales/repositories/sale_repository.dart';
import '../../sales/screens/sales_list_screen.dart';

enum _ViewMode { yearly, monthly, weekly }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = SaleRepository();
  _ViewMode _viewMode = _ViewMode.monthly;

  // Yearly state
  int _year = DateTime.now().year;

  // Monthly state — first day of the displayed month
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  // Weekly state — Monday of the displayed week
  DateTime _weekStart = _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  // Date range for the current view
  DateTime get _periodStart => switch (_viewMode) {
        _ViewMode.yearly => DateTime(_year),
        _ViewMode.monthly => _month,
        _ViewMode.weekly => _weekStart,
      };

  DateTime get _periodEnd => switch (_viewMode) {
        _ViewMode.yearly => DateTime(_year + 1),
        _ViewMode.monthly => DateTime(_month.year, _month.month + 1),
        _ViewMode.weekly => _weekStart.add(const Duration(days: 7)),
      };

  bool get _isCurrentPeriod {
    final now = DateTime.now();
    return switch (_viewMode) {
      _ViewMode.yearly => _year == now.year,
      _ViewMode.monthly =>
        _month.year == now.year && _month.month == now.month,
      _ViewMode.weekly => _weekStart == _mondayOf(now),
    };
  }

  void _previous() => setState(() {
        switch (_viewMode) {
          case _ViewMode.yearly:
            _year--;
          case _ViewMode.monthly:
            _month = DateTime(_month.year, _month.month - 1);
          case _ViewMode.weekly:
            _weekStart = _weekStart.subtract(const Duration(days: 7));
        }
      });

  void _next() {
    if (_isCurrentPeriod) return;
    setState(() {
      switch (_viewMode) {
        case _ViewMode.yearly:
          _year++;
        case _ViewMode.monthly:
          _month = DateTime(_month.year, _month.month + 1);
        case _ViewMode.weekly:
          _weekStart = _weekStart.add(const Duration(days: 7));
      }
    });
  }

  String get _periodLabel => switch (_viewMode) {
        _ViewMode.yearly => '$_year',
        _ViewMode.monthly => DateFormat('MMMM yyyy').format(_month),
        _ViewMode.weekly => () {
            final end = _weekStart.add(const Duration(days: 6));
            return '${DateFormat('d MMM').format(_weekStart)} – ${DateFormat('d MMM yyyy').format(end)}';
          }(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          SegmentedButton<_ViewMode>(
            segments: const [
              ButtonSegment(
                value: _ViewMode.yearly,
                icon: Icon(Icons.calendar_today, size: 18),
                tooltip: 'Year',
              ),
              ButtonSegment(
                value: _ViewMode.monthly,
                icon: Icon(Icons.calendar_month, size: 18),
                tooltip: 'Month',
              ),
              ButtonSegment(
                value: _ViewMode.weekly,
                icon: Icon(Icons.calendar_view_week, size: 18),
                tooltip: 'Week',
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (v) => setState(() => _viewMode = v.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Sale>>(
        stream: _repository.watchSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          final stats = _DashboardStats.compute(all, _periodStart, _periodEnd);

          return ListView(
            padding: const EdgeInsets.all(16),
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
                'Action needed',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              _ActionGrid(stats: stats),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardStats {
  final double paidRevenue;
  final double unpaidRevenue;
  final int paidCount;
  final int unpaidCount;
  final int pendingShipmentCount;
  final int assemblyNotReadyCount;
  final int nifRequiredCount;
  final int overdueCount;

  const _DashboardStats({
    required this.paidRevenue,
    required this.unpaidRevenue,
    required this.paidCount,
    required this.unpaidCount,
    required this.pendingShipmentCount,
    required this.assemblyNotReadyCount,
    required this.nifRequiredCount,
    required this.overdueCount,
  });

  factory _DashboardStats.compute(
    List<Sale> all,
    DateTime start,
    DateTime end,
  ) {
    final period = all.where((s) =>
        !s.createdAt.isBefore(start) && s.createdAt.isBefore(end)).toList();

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return _DashboardStats(
      paidRevenue: period
          .where((s) => s.payment.status == PaymentStatus.paid)
          .fold(0.0, (sum, s) => sum + s.price),
      unpaidRevenue: period
          .where((s) => s.payment.status == PaymentStatus.unpaid)
          .fold(0.0, (sum, s) => sum + s.price),
      paidCount:
          period.where((s) => s.payment.status == PaymentStatus.paid).length,
      unpaidCount:
          period.where((s) => s.payment.status == PaymentStatus.unpaid).length,
      pendingShipmentCount: period
          .where((s) =>
              s.shipment.type == DeliveryType.shipping &&
              s.shipment.status == ShipmentStatus.pending)
          .length,
      assemblyNotReadyCount: period
          .where((s) =>
              s.shipment.status != ShipmentStatus.delivered &&
              s.assemblyStatus != AssemblyStatus.ready)
          .length,
      nifRequiredCount: period
          .where((s) =>
              s.requiresNif &&
              s.shipment.status != ShipmentStatus.delivered)
          .length,
      overdueCount: period
          .where((s) =>
              s.scheduledDate != null &&
              s.scheduledDate!.isBefore(startOfToday) &&
              s.shipment.status != ShipmentStatus.delivered)
          .length,
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
            color: onNext == null
                ? Theme.of(context).disabledColor
                : null,
          ),
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final _DashboardStats stats;
  final String periodLabel;

  const _RevenueCard({required this.stats, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
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
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${stats.paidCount} sale${stats.paidCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            if (stats.unpaidRevenue > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Pending',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color:
                              colorScheme.onPrimaryContainer.withAlpha(180),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(stats.unpaidRevenue),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color:
                              colorScheme.onPrimaryContainer.withAlpha(180),
                        ),
                  ),
                  Text(
                    '${stats.unpaidCount} unpaid',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              colorScheme.onPrimaryContainer.withAlpha(180),
                        ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final _DashboardStats stats;

  const _ActionGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.euro,
        label: 'Unpaid',
        count: stats.unpaidCount,
        color: Colors.orange,
        filter: SaleFilter.unpaid,
      ),
      (
        icon: Icons.local_shipping,
        label: 'Pending shipment',
        count: stats.pendingShipmentCount,
        color: Colors.blue,
        filter: SaleFilter.pendingShipment,
      ),
      (
        icon: Icons.build,
        label: 'Assembly not ready',
        count: stats.assemblyNotReadyCount,
        color: Colors.purple,
        filter: SaleFilter.assemblyNotReady,
      ),
      (
        icon: Icons.badge,
        label: 'NIF required',
        count: stats.nifRequiredCount,
        color: Colors.teal,
        filter: SaleFilter.nifRequired,
      ),
      (
        icon: Icons.warning_amber,
        label: 'Overdue',
        count: stats.overdueCount,
        color: Colors.red,
        filter: SaleFilter.overdue,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items
          .map((item) => _ActionCard(
                icon: item.icon,
                label: item.label,
                count: item.count,
                color: item.color,
                filter: item.filter,
              ))
          .toList(),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final SaleFilter filter;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = count > 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalesListScreen(initialFilter: filter),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon,
                  color: isActive ? color : Colors.grey, size: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isActive ? color : Colors.grey,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
