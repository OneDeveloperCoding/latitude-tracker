import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/widgets/repair_status_colors.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

const Set<RepairStatus> _kDeliveryStatuses = {RepairStatus.done, RepairStatus.returned};

class RepairCard extends StatelessWidget {

  const RepairCard({
    required this.repair, required this.onTap, super.key,
    this.selected = false,
  });
  final Repair repair;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusColor = _statusColor(repair.status, colorScheme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      color: selected ? colorScheme.primaryContainer.withAlpha(80) : null,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              repair.contactName,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(status: repair.status, s: s),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        repair.itemDescription,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Chip(
                            label: Text(repair.itemCategory),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelStyle: theme.textTheme.labelSmall,
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('dd MMM yyyy').format(repair.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (repair.payment.status == PaymentStatus.unpaid) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.payments_outlined,
                              size: 16,
                              color: colorScheme.error,
                            ),
                          ],
                        ],
                      ),
                      if (_kDeliveryStatuses.contains(repair.status)) ...[
                        const SizedBox(height: 6),
                        const Divider(height: 1),
                        const SizedBox(height: 6),
                        _ReturnDeliveryIndicator(
                          delivery: repair.returnDelivery,
                        ),
                      ],
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

  Color _statusColor(RepairStatus status, ColorScheme cs) => switch (status) {
        RepairStatus.received => cs.tertiary,
        RepairStatus.waitingForMaterials => cs.error,
        RepairStatus.inProgress => cs.primary,
        RepairStatus.done => Colors.green,
        RepairStatus.returned => cs.onSurfaceVariant,
      };
}

class _ReturnDeliveryIndicator extends StatelessWidget {

  const _ReturnDeliveryIndicator({required this.delivery});
  final RepairReturnDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, color) = _iconAndColor(cs);
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          _label(context.s),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color),
        ),
      ],
    );
  }

  (IconData, Color) _iconAndColor(ColorScheme cs) {
    if (delivery.type == DeliveryType.pickup) {
      return (Icons.store, Colors.green);
    }
    if (delivery.type == DeliveryType.handDelivery) {
      return delivery.status == ShipmentStatus.delivered
          ? (Icons.directions_walk, Colors.green)
          : (Icons.directions_walk, cs.onSurfaceVariant);
    }
    return switch (delivery.status) {
      ShipmentStatus.pending => (Icons.local_shipping_outlined, cs.onSurfaceVariant),
      ShipmentStatus.shipped => (Icons.local_shipping, Colors.blue),
      ShipmentStatus.delivered => (Icons.local_shipping, Colors.green),
    };
  }

  String _label(AppStrings s) => s.shipmentStatusLabel(delivery.status);
}

class _StatusChip extends StatelessWidget {

  const _StatusChip({required this.status, required this.s});
  final RepairStatus status;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, onColor) = repairStatusContainerColors(status, cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        s.repairStatusLabelFor(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onColor),
      ),
    );
  }
}
