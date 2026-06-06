import 'package:flutter/material.dart';

import 'sale_urgency.dart';

extension UrgencyReasonUI on UrgencyReasonType {
  ({IconData icon, Color color}) get _ui => switch (this) {
        UrgencyReasonType.waitingForMaterials =>
          (icon: Icons.shopping_bag_outlined, color: Colors.orange),
        UrgencyReasonType.assemblyNotReady =>
          (icon: Icons.construction, color: Colors.orange),
        UrgencyReasonType.paymentPending =>
          (icon: Icons.credit_card_off, color: Colors.orange),
        UrgencyReasonType.notYetShipped =>
          (icon: Icons.schedule, color: Colors.red),
      };

  IconData get icon => _ui.icon;
  Color get color => _ui.color;
}
