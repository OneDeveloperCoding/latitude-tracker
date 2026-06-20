import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/constants.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/widgets/payment_method_display.dart';

Future<PaymentMethod?> showMarkPaidSheet(
  BuildContext context,
  SalePayment payment,
) =>
    showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MarkPaidSheet(currentMethod: payment.method),
    );

/// Returns the tracking code and shipped timestamp on confirm, or null if
/// cancelled.
Future<({String trackingCode, DateTime shippedAt})?> showMarkShippedSheet(
  BuildContext context,
  SaleShipment shipment,
) =>
    showModalBottomSheet<({String trackingCode, DateTime shippedAt})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MarkShippedSheet(
        initialTrackingCode: shipment.trackingCode ?? '',
        initialShippedAt: shipment.shippedAt ?? DateTime.now(),
      ),
    );

// ── MarkPaidSheet ────────────────────────────────────────────────────────────

class MarkPaidSheet extends StatefulWidget {
  const MarkPaidSheet({required this.currentMethod, super.key});
  final PaymentMethod currentMethod;

  @override
  State<MarkPaidSheet> createState() => _MarkPaidSheetState();
}

class _MarkPaidSheetState extends State<MarkPaidSheet> {
  late PaymentMethod _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentMethod;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
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
                        title: PaymentMethodDropdownItem(method),
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

// ── MarkShippedSheet ─────────────────────────────────────────────────────────

class MarkShippedSheet extends StatefulWidget {
  const MarkShippedSheet({
    required this.initialTrackingCode,
    required this.initialShippedAt,
    super.key,
  });
  final String initialTrackingCode;
  final DateTime initialShippedAt;

  @override
  State<MarkShippedSheet> createState() => _MarkShippedSheetState();
}

class _MarkShippedSheetState extends State<MarkShippedSheet> {
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  late final TextEditingController _controller;
  late DateTime _shippedAt;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTrackingCode);
    _shippedAt = widget.initialShippedAt;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _shippedAt,
      firstDate: kShippedAtFirstDate,
      lastDate: DateTime.now().add(kShippedAtMaxFutureOffset),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_shippedAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _shippedAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
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
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: s.shippedAtLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.edit_calendar_outlined),
                ),
                child: Text(_dateTimeFormat.format(_shippedAt)),
              ),
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
                  onPressed: () => Navigator.of(context).pop((
                    trackingCode: _controller.text.trim(),
                    shippedAt: _shippedAt,
                  )),
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
