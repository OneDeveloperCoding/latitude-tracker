import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/theme/color_scheme_ext.dart';
import 'package:latitude_tracker/core/widgets/status_indicator_strip.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

StatusIndicatorDot assemblyDot(AssemblyStatus status, ColorScheme cs) {
  final icon =
      status == AssemblyStatus.ready ? Icons.build : Icons.build_outlined;
  final color = switch (status) {
    AssemblyStatus.waitingForMaterials => cs.error,
    AssemblyStatus.notStarted => cs.onSurfaceVariant,
    AssemblyStatus.inProgress => cs.warning,
    AssemblyStatus.ready => cs.success,
  };
  return StatusIndicatorDot(icon: icon, color: color);
}

StatusIndicatorDot paymentDot(SalePayment payment, ColorScheme cs) {
  final isPaid = payment.status == PaymentStatus.paid;
  return StatusIndicatorDot(
    icon: isPaid ? Icons.payments : Icons.payments_outlined,
    color: isPaid ? cs.success : cs.error,
  );
}

StatusIndicatorDot shipmentDot(SaleShipment shipment, ColorScheme cs) {
  final icon = switch (shipment.type) {
    DeliveryType.shipping => Icons.local_shipping_outlined,
    DeliveryType.pickup => Icons.store,
    DeliveryType.handDelivery => Icons.directions_walk,
  };
  final color = switch (shipment.status) {
    ShipmentStatus.pending => cs.error,
    ShipmentStatus.shipped => cs.shipped,
    ShipmentStatus.delivered => cs.success,
  };
  return StatusIndicatorDot(icon: icon, color: color);
}

List<StatusIndicatorDot> saleStatusDots(Sale sale, ColorScheme cs) => [
      paymentDot(sale.payment, cs),
      assemblyDot(sale.derivedAssemblyStatus, cs),
      shipmentDot(sale.shipment, cs),
    ];
