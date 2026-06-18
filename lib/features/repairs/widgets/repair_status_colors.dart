import 'package:flutter/material.dart';

import 'package:latitude_tracker/features/repairs/models/repair.dart';

/// Maps a [RepairStatus] to its (background, foreground) container colors.
/// Shared between the list card badge and the detail screen status picker.
(Color, Color) repairStatusContainerColors(RepairStatus status, ColorScheme cs) =>
    switch (status) {
      RepairStatus.received => (cs.tertiaryContainer, cs.onTertiaryContainer),
      RepairStatus.waitingForMaterials =>
        (cs.errorContainer, cs.onErrorContainer),
      RepairStatus.inProgress => (cs.primaryContainer, cs.onPrimaryContainer),
      RepairStatus.done => (Colors.green.shade100, Colors.green.shade900),
      RepairStatus.returned =>
        (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };
