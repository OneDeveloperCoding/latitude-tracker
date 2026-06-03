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
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get _periodStart => _month;
  DateTime get _periodEnd => DateTime(_month.year, _month.month + 1);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<StoreState<List<Sale>>>(
        valueListenable: SalesStore.state,
        builder: (context, storeState, _) {
          if (storeState is! StoreLoaded<List<Sale>>) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = storeState.data;
          final stats = DashboardStats.compute(all, _periodStart, _periodEnd);

          return ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            children: [
              _MonthTabsControl(
                selectedMonth: _month,
                onMonthSelected: (m) => setState(() => _month = m),
              ),
              const SizedBox(height: 16),
              _RevenueCard(
                stats: stats,
                onInsights: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TrendsScreen(initialPeriod: DashboardPeriod.monthly),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                s.actionNeeded,
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
      ),
    );
  }
}

class _MonthTabsControl extends StatefulWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const _MonthTabsControl({
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  State<_MonthTabsControl> createState() => _MonthTabsControlState();
}

class _MonthTabsControlState extends State<_MonthTabsControl> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months =
        List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));

    return SizedBox(
      height: 36,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: months.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final month = months[i];
          final isSelected = month.year == widget.selectedMonth.year &&
              month.month == widget.selectedMonth.month;
          return ChoiceChip(
            label: Text(DateFormat('MMM yy').format(month)),
            selected: isSelected,
            onSelected: (_) => widget.onMonthSelected(month),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final DashboardStats stats;
  final VoidCallback onInsights;

  const _RevenueCard({required this.stats, required this.onInsights});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            const SizedBox(width: 16),
            InkWell(
              onTap: onInsights,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.onPrimaryContainer.withAlpha(80),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights,
                        color: colorScheme.onPrimaryContainer, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      s.dashboardViewTrends,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 8,
                          ),
                    ),
                  ],
                ),
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

