import 'package:flutter/material.dart';

import '../../../core/theme/color_scheme_ext.dart';
import '../models/sale.dart';
import 'sale_urgency.dart';

extension AssemblyStatusUI on AssemblyStatus {
  IconData get icon => switch (this) {
        AssemblyStatus.notStarted => Icons.build_outlined,
        AssemblyStatus.waitingForMaterials => Icons.shopping_bag_outlined,
        AssemblyStatus.inProgress => Icons.build_outlined,
        AssemblyStatus.ready => Icons.build,
      };

  Color colorOf(ColorScheme cs) => switch (this) {
        AssemblyStatus.notStarted => cs.muted,
        AssemblyStatus.waitingForMaterials => cs.warning,
        AssemblyStatus.inProgress => cs.warning,
        AssemblyStatus.ready => cs.success,
      };
}

extension UrgencyReasonUI on UrgencyReasonType {
  IconData get icon => switch (this) {
        UrgencyReasonType.waitingForMaterials => Icons.shopping_bag_outlined,
        UrgencyReasonType.assemblyNotReady => Icons.construction,
        UrgencyReasonType.paymentPending => Icons.credit_card_off,
        UrgencyReasonType.notYetShipped => Icons.schedule,
      };

  Color colorOf(ColorScheme cs) =>
      this == UrgencyReasonType.notYetShipped ? cs.error : cs.warning;
}
