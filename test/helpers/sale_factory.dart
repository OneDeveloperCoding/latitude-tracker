import 'package:latitude_tracker/features/sales/models/sale.dart';

Sale makeSale({
  AssemblyStatus assembly = AssemblyStatus.ready,
  PaymentStatus payment = PaymentStatus.paid,
  ShipmentStatus shipmentStatus = ShipmentStatus.pending,
  DeliveryType delivery = DeliveryType.shipping,
  DateTime? scheduledDate,
  double price = 50.0,
  bool requiresNif = false,
  DateTime? createdAt,
}) =>
    Sale(
      id: 'test',
      buyerId: 'b1',
      buyerName: 'Test Buyer',
      itemDescription: 'Test Item',
      price: price,
      assemblyStatus: assembly,
      components: const [],
      payment: SalePayment(status: payment, method: PaymentMethod.mbWay),
      shipment: SaleShipment(type: delivery, status: shipmentStatus),
      requiresNif: requiresNif,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      scheduledDate: scheduledDate,
    );
