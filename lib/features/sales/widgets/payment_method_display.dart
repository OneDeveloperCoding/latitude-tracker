import 'package:flutter/material.dart';

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
