import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/theme/color_scheme_ext.dart';
import 'package:latitude_tracker/core/widgets/status_indicator_strip.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/widgets/sale_status_dots.dart';

StatusIndicatorDot repairWorkDot(RepairStatus status, ColorScheme cs) {
  final color = switch (status) {
    RepairStatus.waitingForMaterials => cs.error,
    RepairStatus.received => cs.warning,
    RepairStatus.inProgress => cs.shipped,
    RepairStatus.done => cs.success,
    RepairStatus.returned => cs.onSurfaceVariant,
  };
  return StatusIndicatorDot(icon: Icons.handyman_outlined, color: color);
}

StatusIndicatorDot returnDeliveryDot(
  RepairReturnDelivery delivery,
  ColorScheme cs,
) {
  final icon = switch (delivery.type) {
    DeliveryType.shipping => Icons.local_shipping_outlined,
    DeliveryType.pickup => Icons.store,
    DeliveryType.handDelivery => Icons.directions_walk,
  };
  final color = switch (delivery.status) {
    ShipmentStatus.pending => cs.error,
    ShipmentStatus.shipped => cs.shipped,
    ShipmentStatus.delivered => cs.success,
  };
  return StatusIndicatorDot(icon: icon, color: color);
}

/// Shows the return delivery dot muted when the repair hasn't reached a status
/// where return delivery is relevant (done or returned). Keeps the strip's
/// three slots always visible without implying an overdue return shipment.
StatusIndicatorDot contextualReturnDeliveryDot(Repair repair, ColorScheme cs) {
  const applicable = {RepairStatus.done, RepairStatus.returned};
  final dot = returnDeliveryDot(repair.returnDelivery, cs);
  if (!applicable.contains(repair.status)) {
    return StatusIndicatorDot(icon: dot.icon, color: cs.onSurfaceVariant);
  }
  return dot;
}

List<StatusIndicatorDot> repairStatusDots(Repair repair, ColorScheme cs) => [
      repairWorkDot(repair.status, cs),
      paymentDot(repair.payment, cs),
      contextualReturnDeliveryDot(repair, cs),
    ];
