import 'package:flutter/material.dart';

import '../services/sale_urgency.dart';

extension UrgencyReasonUI on UrgencyReasonType {
  IconData get icon => switch (this) {
        UrgencyReasonType.waitingForMaterials => Icons.shopping_bag_outlined,
        UrgencyReasonType.assemblyNotReady => Icons.construction,
        UrgencyReasonType.paymentPending => Icons.credit_card_off,
        UrgencyReasonType.notYetShipped => Icons.schedule,
      };

  Color get color => switch (this) {
        UrgencyReasonType.waitingForMaterials => Colors.orange,
        UrgencyReasonType.assemblyNotReady => Colors.orange,
        UrgencyReasonType.paymentPending => Colors.orange,
        UrgencyReasonType.notYetShipped => Colors.red,
      };
}
