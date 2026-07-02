import 'package:latitude_tracker/features/sales/models/sale.dart';

/// Which of the 3 tri-indicator sections (Payment, Items/Assembly, Delivery)
/// on the Sale detail screen should start collapsed, derived from the Sale's
/// status at the moment the screen is opened (#193).
class SaleDetailSectionCollapse {
  const SaleDetailSectionCollapse({
    required this.payment,
    required this.items,
    required this.delivery,
  });

  final bool payment;
  final bool items;
  final bool delivery;
}

extension SaleDetailCollapseDerivation on Sale {
  SaleDetailSectionCollapse deriveInitialSectionCollapse() =>
      SaleDetailSectionCollapse(
        payment: payment.status == PaymentStatus.paid,
        items: derivedAssemblyStatus == AssemblyStatus.ready,
        delivery: shipment.status == ShipmentStatus.delivered,
      );
}
