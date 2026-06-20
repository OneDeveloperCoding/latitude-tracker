import 'package:flutter/material.dart';
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

/// Returns the entered tracking code string on confirm (may be empty),
/// or null if the user cancelled.
Future<String?> showMarkShippedSheet(
  BuildContext context,
  SaleShipment shipment,
) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MarkShippedSheet(
        initialTrackingCode: shipment.trackingCode ?? '',
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
  const MarkShippedSheet({required this.initialTrackingCode, super.key});
  final String initialTrackingCode;

  @override
  State<MarkShippedSheet> createState() => _MarkShippedSheetState();
}

class _MarkShippedSheetState extends State<MarkShippedSheet> {
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
