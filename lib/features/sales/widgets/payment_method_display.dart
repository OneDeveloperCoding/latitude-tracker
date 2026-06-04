import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../models/sale.dart';

/// Brand-inspired colours for each payment method.
/// Chosen for visual distinctiveness within the app — not exact brand hex codes.
Color paymentMethodColor(PaymentMethod m) => switch (m) {
      PaymentMethod.mbWay => const Color(0xFF0080C9),
      PaymentMethod.revolut => const Color(0xFF7C3AED),
      PaymentMethod.paypal => const Color(0xFF009CDE),
      PaymentMethod.cash => const Color(0xFF43A047),
      PaymentMethod.sumup => const Color(0xFF00C4A7),
      PaymentMethod.bankTransfer => const Color(0xFF78909C),
    };

/// Coloured dot + label row used in payment method dropdowns.
class PaymentMethodDropdownItem extends StatelessWidget {
  final PaymentMethod method;

  const PaymentMethodDropdownItem(this.method, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: paymentMethodColor(method),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(context.s.paymentMethodLabel(method)),
      ],
    );
  }
}
