import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/constants.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/theme/color_scheme_ext.dart';
import 'package:latitude_tracker/core/widgets/status_indicator_strip.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/screens/sale_card_sheets.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency_ui.dart';
import 'package:latitude_tracker/features/sales/widgets/sale_status_dots.dart';

const _kBadgeRadius = BorderRadius.all(Radius.circular(20));

class SaleCard extends StatefulWidget {
  const SaleCard({
    required this.sale,
    required this.buyerNif,
    required this.onTap,
    required this.onMarkPaid,
    required this.onMarkShipped,
    super.key,
    this.isSelected = false,
  });

  final Sale sale;
  final String? buyerNif;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(PaymentMethod method) onMarkPaid;
  final void Function({
    required DateTime shippedAt,
    String? trackingCode,
  }) onMarkShipped;

  @override
  State<SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<SaleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final level = sale.urgencyLevel();
    final reasons = sale.urgencyReasons(level: level);
    final cs = Theme.of(context).colorScheme;
    final s = context.s;

    final canMarkPaid = sale.payment.status == PaymentStatus.unpaid;
    final canMarkShipped =
        sale.shipment.type == DeliveryType.shipping &&
        sale.shipment.status == ShipmentStatus.pending;

    return Slidable(
      key: ValueKey(sale.id),
      startActionPane: canMarkPaid
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.35,
              children: [
                SlidableAction(
                  onPressed: (_) async {
                    final method = await showMarkPaidSheet(
                      context,
                      sale.payment,
                    );
                    if (!mounted || method == null) return;
                    widget.onMarkPaid(method);
                  },
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                  icon: Icons.payments_outlined,
                  label: s.swipeActionMarkPaid,
                ),
              ],
            )
          : null,
      endActionPane: canMarkShipped
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.35,
              children: [
                SlidableAction(
                  onPressed: (_) async {
                    final result = await showMarkShippedSheet(
                      context,
                      sale.shipment,
                    );
                    if (!mounted || result == null) return;
                    widget.onMarkShipped(
                      shippedAt: result.shippedAt,
                      trackingCode: result.trackingCode.isEmpty
                          ? null
                          : result.trackingCode,
                    );
                  },
                  backgroundColor: cs.secondaryContainer,
                  foregroundColor: cs.onSecondaryContainer,
                  icon: Icons.local_shipping_outlined,
                  label: s.swipeActionMarkShipped,
                ),
              ],
            )
          : null,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 12),
        color: widget.isSelected ? cs.primaryContainer : null,
        child: InkWell(
          onTap: widget.onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: StatusIndicatorStrip(
                    dots: saleStatusDots(sale, cs),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 12, 10),
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
                          onToggle: () =>
                              setState(() => _expanded = !_expanded),
                        ),
                        const SizedBox(height: 4),
                        _DatesRow(sale: sale),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ItemsRow extends StatelessWidget {
  const _ItemsRow({
    required this.sale,
    required this.reasons,
    required this.buyerNif,
    required this.expanded,
    required this.onToggle,
  });

  final Sale sale;
  final List<UrgencyReasonType> reasons;
  final String? buyerNif;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final items = sale.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final hasMultiple = items.length > 1;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            // Null for single-item cards: the outer card InkWell handles the
            // tap, avoiding a duplicate navigation call.
            onTap: hasMultiple ? onToggle : null,
            borderRadius: BorderRadius.circular(4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  if (hasMultiple)
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
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
            borderRadius: _kBadgeRadius,
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
            borderRadius: _kBadgeRadius,
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
            borderRadius: _kBadgeRadius,
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
            borderRadius: _kBadgeRadius,
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

/// Three-slot date row: bought (left) · shipped (centre) · scheduled (right).
/// Slots that have no value are omitted; remaining slots keep their positions
/// using a [Stack] so absent slots don't shift siblings.
class _DatesRow extends StatelessWidget {
  const _DatesRow({required this.sale});
  static final _shortFormat = DateFormat('dd MMM');
  static final _longFormat = DateFormat('dd MMM yyyy');
  final Sale sale;

  Color _scheduledColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDelivered = sale.shipment.status == ShipmentStatus.delivered;
    final days = sale.daysUntilScheduled()!;
    if (isDelivered || days > 3) return cs.onSurfaceVariant;
    if (days <= 2) return cs.error;
    return cs.warning;
  }

  String _scheduledLabel(AppStrings s) {
    final days = sale.daysUntilScheduled()!;
    final isDelivered = sale.shipment.status == ShipmentStatus.delivered;
    final formatted = _shortFormat.format(sale.scheduledDate!);
    if (isDelivered) return formatted;
    if (days < 0) return '$formatted (${s.daysOverdue(days.abs())})';
    if (days == 0) return s.today;
    if (days == 1) return s.tomorrow;
    return formatted;
  }

  Widget _slot(BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required FontWeight fontWeight,
  }) {
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: color, fontWeight: fontWeight);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color, semanticLabel: ''),
        const SizedBox(width: 3),
        Text(
          text,
          style: style,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = context.s;
    final muted = cs.onSurfaceVariant;

    final hasShipped = sale.shipment.type == DeliveryType.shipping &&
        sale.shipment.shippedAt != null;
    final hasScheduled = sale.scheduledDate != null;

    return Row(
      children: [
        _slot(
          context,
          icon: Icons.shopping_bag_outlined,
          text: _longFormat.format(sale.createdAt),
          color: muted,
          fontWeight: FontWeight.normal,
        ),
        if (hasShipped) ...[
          const Spacer(),
          _slot(
            context,
            icon: Icons.local_shipping_outlined,
            text: _shortFormat.format(sale.shipment.shippedAt!),
            color: muted,
            fontWeight: FontWeight.normal,
          ),
        ],
        if (hasScheduled) ...[
          const Spacer(),
          _slot(
            context,
            icon: Icons.event,
            text: _scheduledLabel(s),
            color: _scheduledColor(context),
            fontWeight: FontWeight.w500,
          ),
        ],
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
