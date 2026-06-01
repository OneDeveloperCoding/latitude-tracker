import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/sales_store.dart';
import '../../../core/store/store_state.dart';
import '../models/sale.dart';
import '../services/sale_urgency.dart';
import 'sale_detail_screen.dart';

const _urgencyOrder = {UrgencyLevel.overdue: 0, UrgencyLevel.thisWeek: 1, UrgencyLevel.none: 2};

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.shoppingList)),
      body: ValueListenableBuilder<StoreState<List<Sale>>>(
        valueListenable: SalesStore.state,
        builder: (context, storeState, _) {
          if (storeState is! StoreLoaded<List<Sale>>) {
            return const Center(child: CircularProgressIndicator());
          }

          final openSales = storeState.data
              .where((s) =>
                  s.assemblyStatus != AssemblyStatus.ready &&
                  s.shipment.status != ShipmentStatus.delivered &&
                  s.components.any((c) => !c.isAvailable))
              .toList()
            ..sort((a, b) => _urgencyOrder[a.urgencyLevel()]!
                .compareTo(_urgencyOrder[b.urgencyLevel()]!));

          if (openSales.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(s.nothingLeftToBuy),
                ],
              ),
            );
          }

          final totalNeeded = openSales
              .expand((s) => s.components.where((c) => !c.isAvailable))
              .length;
          final urgentCount =
              openSales.where((s) => s.urgencyLevel() != UrgencyLevel.none).length;

          return ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            children: [
              _ShoppingListHeader(
                totalNeeded: totalNeeded,
                totalSales: openSales.length,
                urgentCount: urgentCount,
              ),
              const SizedBox(height: 16),
              ...openSales.map((sale) => _SaleMaterialsCard(
                    sale: sale,
                    urgency: sale.urgencyLevel(),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _ShoppingListHeader extends StatelessWidget {
  final int totalNeeded;
  final int totalSales;
  final int urgentCount;

  const _ShoppingListHeader({
    required this.totalNeeded,
    required this.totalSales,
    required this.urgentCount,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Row(
      children: [
        Text(
          s.itemsAcrossSales(totalNeeded, totalSales),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (urgentCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: Theme.of(context).colorScheme.error.withAlpha(100)),
            ),
            child: Text(
              s.nUrgent(urgentCount),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SaleMaterialsCard extends StatelessWidget {
  final Sale sale;
  final UrgencyLevel urgency;

  const _SaleMaterialsCard({required this.sale, required this.urgency});

  Color? _accentColor(BuildContext context) => switch (urgency) {
        UrgencyLevel.overdue => Theme.of(context).colorScheme.error,
        UrgencyLevel.thisWeek => Colors.amber[700],
        UrgencyLevel.none => null,
      };

  @override
  Widget build(BuildContext context) {
    final needed = sale.components.where((c) => !c.isAvailable).toList();
    final accent = _accentColor(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SaleDetailScreen(saleId: sale.id)),
        ),
        child: Container(
        decoration: accent != null
            ? BoxDecoration(
                border: Border(left: BorderSide(color: accent, width: 4)))
            : null,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sale.buyerName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sale.scheduledDate != null) ...[
                  const SizedBox(width: 8),
                  _DueDateLabel(sale: sale, urgency: urgency),
                ],
                const SizedBox(width: 8),
                _AssemblyBadge(status: sale.assemblyStatus),
              ],
            ),
            Text(
              sale.itemDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            ...needed.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text(c.name, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _DueDateLabel extends StatelessWidget {
  final Sale sale;
  final UrgencyLevel urgency;

  const _DueDateLabel({required this.sale, required this.urgency});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduled = DateTime(
      sale.scheduledDate!.year,
      sale.scheduledDate!.month,
      sale.scheduledDate!.day,
    );
    final days = scheduled.difference(today).inDays;

    final Color color = switch (urgency) {
      UrgencyLevel.overdue => Theme.of(context).colorScheme.error,
      UrgencyLevel.thisWeek => Colors.amber[700]!,
      UrgencyLevel.none => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    final String label = urgency == UrgencyLevel.overdue
        ? s.daysOverdue(days.abs())
        : days == 0
            ? s.today
            : days == 1
                ? s.tomorrow
                : DateFormat('dd MMM').format(sale.scheduledDate!);

    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

class _AssemblyBadge extends StatelessWidget {
  final AssemblyStatus status;

  const _AssemblyBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final (color, label) = switch (status) {
      AssemblyStatus.notStarted =>
        (Colors.red, s.assemblyLabel(AssemblyStatus.notStarted)),
      AssemblyStatus.waitingForMaterials =>
        (Colors.amber[700]!, s.assemblyLabel(AssemblyStatus.waitingForMaterials)),
      AssemblyStatus.inProgress =>
        (Colors.orange, s.assemblyLabel(AssemblyStatus.inProgress)),
      AssemblyStatus.ready =>
        (Colors.green, s.assemblyLabel(AssemblyStatus.ready)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
