import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/constants.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/theme/color_scheme_ext.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency_ui.dart';

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
  final void Function({String? trackingCode}) onMarkShipped;

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
    final s = context.s;

    final accentColor = reasons.isEmpty
        ? null
        : level == UrgencyLevel.overdue
            ? cs.error
            : cs.warning;

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
                  onPressed: (ctx) async {
                    final method = await _showMarkPaidSheet(
                      context,
                      sale.payment,
                      s,
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
                  onPressed: (ctx) async {
                    final code = await _showMarkShippedSheet(
                      context,
                      sale.shipment,
                      s,
                    );
                    if (!mounted || code == null) return;
                    widget.onMarkShipped(
                      trackingCode: code.isEmpty ? null : code,
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
      ),
    );
  }
}

// ── Bottom sheet helpers ─────────────────────────────────────────────────────

Future<PaymentMethod?> _showMarkPaidSheet(
  BuildContext context,
  SalePayment payment,
  AppStrings s,
) =>
    showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _MarkPaidSheet(
        currentMethod: payment.method,
        strings: s,
      ),
    );

/// Returns the entered tracking code string on confirm (may be empty),
/// or null if the user cancelled.
Future<String?> _showMarkShippedSheet(
  BuildContext context,
  SaleShipment shipment,
  AppStrings s,
) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _MarkShippedSheet(
        initialTrackingCode: shipment.trackingCode ?? '',
        strings: s,
      ),
    );

// ── _MarkPaidSheet ───────────────────────────────────────────────────────────

class _MarkPaidSheet extends StatefulWidget {
  const _MarkPaidSheet({
    required this.currentMethod,
    required this.strings,
  });

  final PaymentMethod currentMethod;
  final AppStrings strings;

  @override
  State<_MarkPaidSheet> createState() => _MarkPaidSheetState();
}

class _MarkPaidSheetState extends State<_MarkPaidSheet> {
  late PaymentMethod _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentMethod;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: cs.primary),
                const SizedBox(width: 12),
                Text(s.markAsPaidTitle,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            RadioGroup<PaymentMethod>(
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v!),
              child: Column(
                children: kPaymentMethodOrder
                    .map(
                      (method) => RadioListTile<PaymentMethod>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.paymentMethodLabel(method)),
                        value: method,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(s.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: Text(s.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── _MarkShippedSheet ────────────────────────────────────────────────────────

class _MarkShippedSheet extends StatefulWidget {
  const _MarkShippedSheet({
    required this.initialTrackingCode,
    required this.strings,
  });

  final String initialTrackingCode;
  final AppStrings strings;

  @override
  State<_MarkShippedSheet> createState() => _MarkShippedSheetState();
}

class _MarkShippedSheetState extends State<_MarkShippedSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTrackingCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: cs.secondary),
                const SizedBox(width: 12),
                Text(s.markAsShippedTitle,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: s.cttTrackingLabel,
                hintText: s.cttTrackingHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(s.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_controller.text.trim()),
                  child: Text(s.save),
                ),
              ],
            ),
          ],
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
      decoration: BoxDecoration(color: bg, borderRadius: _kBadgeRadius),
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

class _ScheduledDateLabel extends StatelessWidget {
  const _ScheduledDateLabel({required this.sale});
  static final _dateFormat = DateFormat('dd MMM');
  final Sale sale;

  Color _color(BuildContext context, int days, bool isDelivered) {
    final cs = Theme.of(context).colorScheme;
    if (isDelivered || days > 3) return cs.onSurfaceVariant;
    if (days <= 2) return cs.error;
    return cs.warning;
  }

  String _label(AppStrings s, int days, bool isDelivered) {
    final formatted = _dateFormat.format(sale.scheduledDate!);
    if (isDelivered) return formatted;
    if (days < 0) return '$formatted (${s.daysOverdue(days.abs())})';
    if (days == 0) return s.today;
    if (days == 1) return s.tomorrow;
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final days = sale.daysUntilScheduled()!;
    final isDelivered = sale.shipment.status == ShipmentStatus.delivered;
    final color = _color(context, days, isDelivered);
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
            _label(s, days, isDelivered),
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
