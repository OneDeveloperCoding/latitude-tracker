import 'package:flutter/material.dart';

import '../../../core/theme/color_scheme_ext.dart';
import 'sale_urgency.dart';

extension UrgencyReasonUI on UrgencyReasonType {
  IconData get icon => switch (this) {
        UrgencyReasonType.waitingForMaterials => Icons.shopping_bag_outlined,
        UrgencyReasonType.assemblyNotReady => Icons.construction,
        UrgencyReasonType.paymentPending => Icons.credit_card_off,
        UrgencyReasonType.notYetShipped => Icons.schedule,
      };

  Color colorOf(ColorScheme cs) => switch (this) {
        UrgencyReasonType.waitingForMaterials => cs.warning,
        UrgencyReasonType.assemblyNotReady => cs.warning,
        UrgencyReasonType.paymentPending => cs.warning,
        UrgencyReasonType.notYetShipped => cs.error,
      };
}
