import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/widgets/status_indicator_strip.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/widgets/repair_status_dots.dart';

class RepairCard extends StatelessWidget {
  const RepairCard({
    required this.repair,
    required this.onTap,
    super.key,
    this.selected = false,
  });
  final Repair repair;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: StatusIndicatorStrip(
                  dots: repairStatusDots(repair, colorScheme),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ContactRow(repair: repair),
                      const SizedBox(height: 2),
                      _WorkRow(repair: repair),
                      const SizedBox(height: 4),
                      _DatesRow(repair: repair),
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.repair});
  final Repair repair;

  @override
  Widget build(BuildContext context) {
    final cost = repair.materialsCost;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            repair.contactName,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (cost != null) ...[
          const SizedBox(width: 8),
          Text(
            '€${cost.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ],
    );
  }
}

/// Item description (primary) with a problem snippet below (muted).
/// Mirrors the items row in SaleCard: the middle row aligns with the work dot.
class _WorkRow extends StatelessWidget {
  const _WorkRow({required this.repair});
  final Repair repair;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          repair.itemDescription,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (repair.problemDescription.isNotEmpty)
          Text(
            repair.problemDescription,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _DatesRow extends StatelessWidget {
  const _DatesRow({required this.repair});
  static final _longFormat = DateFormat('dd MMM yyyy');
  final Repair repair;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = cs.onSurfaceVariant;
    final style =
        Theme.of(context).textTheme.labelSmall?.copyWith(color: color);
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 11, color: color, semanticLabel: ''),
        const SizedBox(width: 3),
        Text(_longFormat.format(repair.createdAt), style: style),
      ],
    );
  }
}
