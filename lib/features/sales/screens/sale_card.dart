import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/constants.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/theme/color_scheme_ext.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency_ui.dart';

class SaleCard extends StatefulWidget {
  const SaleCard({
    required this.sale,
    required this.buyerNif,
    required this.onTap,
    super.key,
    this.isSelected = false,
  });

  final Sale sale;
  final String? buyerNif;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<SaleCard> {
  bool _expanded = false;
  static final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final level = sale.urgencyLevel();
    final reasons = sale.urgencyReasons(level: level);
    final cs = Theme.of(context).colorScheme;
    final accentColor = reasons.isEmpty
        ? null
        : level == UrgencyLevel.overdue
            ? cs.error
            : cs.warning;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      color: widget.isSelected ? cs.primaryContainer : null,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: accentColor != null
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: accentColor, width: 7),
                  ),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: 8),
                  Text(
                    '€${sale.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              _ItemsRow(
                sale: sale,
                reasons: reasons,
                buyerNif: widget.buyerNif,
                expanded: _expanded,
                onToggle: () => setState(() => _expanded = !_expanded),
                onCardTap: widget.onTap,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _dateFormat.format(sale.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  if (sale.scheduledDate != null)
                    Flexible(child: _ScheduledDateLabel(sale: sale)),
                ],
              ),
              const SizedBox(height: 8),
              _SaleStageChip(sale: sale),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemsRow extends StatelessWidget {
  const _ItemsRow({
    required this.sale,
    required this.reasons,
    required this.buyerNif,
    required this.expanded,
    required this.onToggle,
    required this.onCardTap,
  });

  final Sale sale;
  final List<UrgencyReasonType> reasons;
  final String? buyerNif;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onCardTap;

  @override
  Widget build(BuildContext context) {
    final items = sale.items;
    final hasMultiple = items.length > 1;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: hasMultiple ? onToggle : onCardTap,
            borderRadius: BorderRadius.circular(4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  if (hasMultiple)
                    Icon(
                      expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  if (hasMultiple) const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: expanded
                          ? items
                              .map((i) => _itemLine(context, i.description))
                              .toList()
                          : [_itemLine(context, items.first.description)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AttentionBadges(sale: sale, reasons: reasons, buyerNif: buyerNif),
      ],
    );
  }

  Widget _itemLine(BuildContext context, String description) => Text(
        description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      );
}

class _SaleStageChip extends StatelessWidget {
  const _SaleStageChip({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cs = Theme.of(context).colorScheme;
    final stage = sale.stage;

    final (Color bg, Color fg) = switch (stage) {
      SaleStage.assembly => (cs.errorContainer, cs.onErrorContainer),
      SaleStage.payment  => (cs.tertiaryContainer, cs.onTertiaryContainer),
      SaleStage.shipment => (cs.secondaryContainer, cs.onSecondaryContainer),
      SaleStage.done     => (cs.primaryContainer, cs.onPrimaryContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        s.saleStageLabel(stage),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({required this.category, super.key});
  final String category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}

class AttentionBadges extends StatelessWidget {
  const AttentionBadges({
    required this.sale,
    required this.reasons,
    required this.buyerNif,
    super.key,
  });
  final Sale sale;
  final List<UrgencyReasonType> reasons;
  final String? buyerNif;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cs = Theme.of(context).colorScheme;
    final buyerHasNif = buyerNif?.isNotEmpty == true;
    final isPaid = sale.payment.status == PaymentStatus.paid;

    // Hidden when buyer has NIF but sale is unpaid (nothing to act on yet).
    final showNifBadge = sale.requiresNif && (!buyerHasNif || isPaid);
    final nifBadgeColor = !buyerHasNif
        ? cs.warning
        : sale.atSubmissionDone
            ? cs.success
            : cs.pending;

    final isReadyButUnpaid =
        sale.derivedAssemblyStatus == AssemblyStatus.ready &&
            sale.payment.status == PaymentStatus.unpaid &&
            sale.shipment.status != ShipmentStatus.delivered;

    final hasNote = sale.notes?.isNotEmpty == true;

    if (!hasNote && !showNifBadge && !isReadyButUnpaid && reasons.isEmpty) {
      return const SizedBox.shrink();
    }

    // Order: note → NIF → ready-but-unpaid → urgency warnings.
    // Warnings are rightmost so they catch the eye first when scanning
    // right-to-left.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasNote) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showNotePreview(context, sale.notes!),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Icon(
                Icons.sticky_note_2_outlined,
                size: 22,
                semanticLabel: s.sectionNotes,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (showNifBadge) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () =>
                _showNifDetail(context, buyerHasNif, sale.atSubmissionDone),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Icon(
                kNifIcon,
                size: 22,
                semanticLabel: s.nifRequired,
                color: nifBadgeColor,
              ),
            ),
          ),
        ],
        if (isReadyButUnpaid) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showReadyButUnpaidDetail(context),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Icon(
                Icons.price_check,
                size: 22,
                semanticLabel: s.readyButUnpaidTitle,
                color: cs.warning,
              ),
            ),
          ),
        ],
        if (reasons.isNotEmpty) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showUrgencyDetail(context, reasons),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Icon(
                reasons.length == 1
                    ? reasons.first.icon
                    : Icons.warning_amber_rounded,
                size: 22,
                semanticLabel: reasons.length == 1
                    ? s.urgencyReasonLabel(reasons.first)
                    : s.urgencySheetTitle,
                color: reasons.length == 1
                    ? reasons.first.colorOf(cs)
                    : cs.warning,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ScheduledDateLabel extends StatelessWidget {
  const _ScheduledDateLabel({required this.sale});
  static final _dateFormat = DateFormat('dd MMM');
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final days = sale.daysUntilScheduled()!;
    final isDelivered = sale.shipment.status == ShipmentStatus.delivered;

    final Color color;
    if (isDelivered) {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    } else if (days < 0) {
      color = Theme.of(context).colorScheme.error;
    } else if (days <= 2) {
      color = Theme.of(context).colorScheme.error;
    } else if (days <= 3) {
      color = Theme.of(context).colorScheme.warning;
    } else {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    final formattedDate = _dateFormat.format(sale.scheduledDate!);
    final String label;
    if (isDelivered) {
      label = formattedDate;
    } else if (days < 0) {
      label = '$formattedDate (${s.daysOverdue(days.abs())})';
    } else if (days == 0) {
      label = s.today;
    } else if (days == 1) {
      label = s.tomorrow;
    } else {
      label = formattedDate;
    }

    final textStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: color, fontWeight: FontWeight.w500);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event, size: 12, color: color, semanticLabel: ''),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}

void _showNotePreview(BuildContext context, String notes) {
  final s = context.s;
  unawaited(showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sticky_note_2_outlined,
                  color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 12),
              Text(s.sectionNotes,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(notes, style: Theme.of(ctx).textTheme.bodyMedium),
        ],
      ),
    ),
  ));
}

void _showNifDetail(
    BuildContext context, bool buyerHasNif, bool atSubmissionDone) {
  final s = context.s;
  final String title;
  final String body;
  final Color iconColor;

  final cs = Theme.of(context).colorScheme;
  if (!buyerHasNif) {
    title = s.noNifOnFile;
    body = s.nifSheetBody;
    iconColor = cs.warning;
  } else if (atSubmissionDone) {
    title = s.atFiledWithAt;
    body = s.atFiledWithAtBody;
    iconColor = cs.success;
  } else {
    title = s.nifSheetTitle;
    body = s.nifSheetBody;
    iconColor = cs.pending;
  }

  unawaited(showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(kNifIcon, color: iconColor),
              const SizedBox(width: 12),
              Text(title,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: Theme.of(ctx).textTheme.bodyMedium),
        ],
      ),
    ),
  ));
}

void _showReadyButUnpaidDetail(BuildContext context) {
  final s = context.s;
  unawaited(showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.price_check,
                  color: Theme.of(ctx).colorScheme.warning),
              const SizedBox(width: 12),
              Text(s.readyButUnpaidTitle,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(s.readyButUnpaidBody,
              style: Theme.of(ctx).textTheme.bodyMedium),
        ],
      ),
    ),
  ));
}

void _showUrgencyDetail(
    BuildContext context, List<UrgencyReasonType> reasons) {
  final s = context.s;
  unawaited(showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.urgencySheetTitle,
              style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...reasons.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(r.icon, size: 20,
                      color: r.colorOf(Theme.of(ctx).colorScheme)),
                  const SizedBox(width: 12),
                  Text(s.urgencyReasonLabel(r),
                      style: Theme.of(ctx).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ));
}
