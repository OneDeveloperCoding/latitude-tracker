import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/theme/color_scheme_ext.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency_ui.dart';

class SaleProgressPath extends StatelessWidget {
  const SaleProgressPath({required this.sale, super.key});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        _assemblyNode(cs),
        _line(cs, sale.derivedAssemblyStatus == AssemblyStatus.ready),
        _paymentNode(cs),
        _line(cs, sale.payment.status == PaymentStatus.paid),
        _shipmentNode(cs),
      ],
    );
  }

  Widget _assemblyNode(ColorScheme cs) {
    final status = sale.derivedAssemblyStatus;
    return PathNode(icon: status.icon, color: status.colorOf(cs));
  }

  Widget _paymentNode(ColorScheme cs) {
    final paid = sale.payment.status == PaymentStatus.paid;
    return PathNode(
      icon: paid ? Icons.payments : Icons.payments_outlined,
      color: paid ? cs.success : cs.muted,
    );
  }

  Widget _shipmentNode(ColorScheme cs) {
    if (sale.shipment.type == DeliveryType.pickup) {
      return PathNode(icon: Icons.store, color: cs.success);
    }
    if (sale.shipment.type == DeliveryType.handDelivery) {
      return PathNode(
        icon: Icons.directions_walk,
        color: sale.shipment.status == ShipmentStatus.delivered
            ? cs.success
            : cs.muted,
      );
    }
    final (icon, color) = switch (sale.shipment.status) {
      ShipmentStatus.pending => (Icons.local_shipping_outlined, cs.muted),
      ShipmentStatus.shipped => (Icons.local_shipping, cs.shipped),
      ShipmentStatus.delivered => (Icons.local_shipping, cs.success),
    };
    return PathNode(icon: icon, color: color);
  }

  Widget _line(ColorScheme cs, bool active) => Expanded(
        child: Container(
          height: 2,
          color: active ? cs.success : cs.surfaceContainerHighest,
        ),
      );
}

class PathNode extends StatelessWidget {
  const PathNode({required this.icon, required this.color, super.key});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Center(child: Icon(icon, size: 16, color: color)),
    );
  }
}

class LegendRow extends StatelessWidget {
  const LegendRow(this.icon, this.color, this.label, {super.key});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

void showPathLegend(BuildContext context, AppStrings s) {
  final cs = Theme.of(context).colorScheme;
  unawaited(showModalBottomSheet<void>(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.legendTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          for (final status in AssemblyStatus.values)
            LegendRow(status.icon, status.colorOf(cs),
                '${s.assemblyLegendHeader}: ${status.labelOf(s)}'),
          const Divider(height: 20),
          LegendRow(Icons.payments_outlined, cs.muted,
              '${s.paymentLegendHeader}: ${s.unpaid}'),
          LegendRow(Icons.payments, cs.success,
              '${s.paymentLegendHeader}: ${s.paid}'),
          const Divider(height: 20),
          LegendRow(
            Icons.local_shipping_outlined,
            cs.muted,
            '${s.shipmentLegendHeader}: '
            '${s.shipmentStatusLabel(ShipmentStatus.pending)}',
          ),
          LegendRow(
            Icons.local_shipping,
            cs.shipped,
            '${s.shipmentLegendHeader}: '
            '${s.shipmentStatusLabel(ShipmentStatus.shipped)}',
          ),
          LegendRow(
            Icons.local_shipping,
            cs.success,
            '${s.shipmentLegendHeader}: '
            '${s.shipmentStatusLabel(ShipmentStatus.delivered)}',
          ),
          LegendRow(Icons.store, cs.success, s.pickupNoShipment),
          LegendRow(Icons.directions_walk, cs.success, s.handDelivery),
        ],
      ),
    ),
  ));
}
