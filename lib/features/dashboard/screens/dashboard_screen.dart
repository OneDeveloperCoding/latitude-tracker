import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../sales/models/sale.dart';
import '../../sales/repositories/sale_repository.dart';
import '../../sales/screens/sales_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = SaleRepository();
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      });

  void _nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isBefore(DateTime.now().add(const Duration(days: 1)))) {
      setState(() => _selectedMonth = next);
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: StreamBuilder<List<Sale>>(
        stream: _repository.watchSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allSales = snapshot.data ?? [];
          final stats = _DashboardStats.compute(allSales, _selectedMonth);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MonthHeader(
                month: _selectedMonth,
                onPrevious: _previousMonth,
                onNext: _isCurrentMonth ? null : _nextMonth,
              ),
              const SizedBox(height: 16),
              _RevenueCard(stats: stats),
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

  factory _DashboardStats.compute(List<Sale> all, DateTime month) {
    final monthSales = all.where((s) =>
        s.createdAt.year == month.year &&
        s.createdAt.month == month.month);

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return _DashboardStats(
      paidRevenue: monthSales
          .where((s) => s.payment.status == PaymentStatus.paid)
          .fold(0, (sum, s) => sum + s.price),
      unpaidRevenue: monthSales
          .where((s) => s.payment.status == PaymentStatus.unpaid)
          .fold(0, (sum, s) => sum + s.price),
      paidCount: monthSales
          .where((s) => s.payment.status == PaymentStatus.paid)
          .length,
      unpaidCount: all
          .where((s) => s.payment.status == PaymentStatus.unpaid)
          .length,
      pendingShipmentCount: all
          .where((s) =>
              s.shipment.type == DeliveryType.shipping &&
              s.shipment.status == ShipmentStatus.pending)
          .length,
      assemblyNotReadyCount: all
          .where((s) =>
              s.shipment.status != ShipmentStatus.delivered &&
              s.assemblyStatus != AssemblyStatus.ready)
          .length,
      nifRequiredCount: all
          .where((s) =>
              s.requiresNif &&
              s.shipment.status != ShipmentStatus.delivered)
          .length,
      overdueCount: all
          .where((s) =>
              s.scheduledDate != null &&
              s.scheduledDate!.isBefore(startOfToday) &&
              s.shipment.status != ShipmentStatus.delivered)
          .length,
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const _MonthHeader({
    required this.month,
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
        Text(
          DateFormat('MMMM yyyy').format(month),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          color: onNext == null
              ? Theme.of(context).disabledColor
              : null,
        ),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final _DashboardStats stats;

  const _RevenueCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This month',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        '${stats.paidCount} sale${stats.paidCount == 1 ? '' : 's'} received',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        currencyFormat.format(stats.unpaidRevenue),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withAlpha(180),
                            ),
                      ),
                      Text(
                        '${stats.unpaidCount} unpaid',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withAlpha(180),
                                ),
                      ),
                    ],
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _ActionCard(
          icon: Icons.euro,
          label: 'Unpaid',
          count: stats.unpaidCount,
          color: Colors.orange,
          filter: SaleFilter.unpaid,
        ),
        _ActionCard(
          icon: Icons.local_shipping,
          label: 'Pending shipment',
          count: stats.pendingShipmentCount,
          color: Colors.blue,
          filter: SaleFilter.pendingShipment,
        ),
        _ActionCard(
          icon: Icons.build,
          label: 'Assembly not ready',
          count: stats.assemblyNotReadyCount,
          color: Colors.purple,
          filter: SaleFilter.assemblyNotReady,
        ),
        _ActionCard(
          icon: Icons.badge,
          label: 'NIF required',
          count: stats.nifRequiredCount,
          color: Colors.teal,
          filter: SaleFilter.nifRequired,
        ),
        _ActionCard(
          icon: Icons.warning_amber,
          label: 'Overdue',
          count: stats.overdueCount,
          color: Colors.red,
          filter: SaleFilter.assemblyNotReady,
        ),
      ],
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: count == 0
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SalesListScreen(initialFilter: filter),
                  ),
                ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: count > 0 ? color : Colors.grey, size: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: count > 0 ? color : Colors.grey,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: count > 0
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
