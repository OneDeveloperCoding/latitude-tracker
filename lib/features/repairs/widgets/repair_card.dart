import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../sales/models/sale.dart';
import '../models/repair.dart';

class RepairCard extends StatelessWidget {
  final Repair repair;
  final VoidCallback onTap;
  final bool selected;

  const RepairCard({
    super.key,
    required this.repair,
    required this.onTap,
    this.selected = false,
  });

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
                            DateFormat('d MMM y').format(repair.createdAt),
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

class _StatusChip extends StatelessWidget {
  final RepairStatus status;
  final AppStrings s;

  const _StatusChip({required this.status, required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, onColor) = switch (status) {
      RepairStatus.received => (cs.tertiaryContainer, cs.onTertiaryContainer),
      RepairStatus.waitingForMaterials =>
        (cs.errorContainer, cs.onErrorContainer),
      RepairStatus.inProgress =>
        (cs.primaryContainer, cs.onPrimaryContainer),
      RepairStatus.done => (Colors.green.shade100, Colors.green.shade900),
      RepairStatus.returned =>
        (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };

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
