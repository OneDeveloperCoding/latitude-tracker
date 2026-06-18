import 'package:latitude_tracker/features/sales/models/sale.dart';

SaleItem makeSaleItem({
  String id = 'item-1',
  String description = 'Test Item',
  String category = 'necklace',
  double price = 50.0,
  AssemblyStatus assembly = AssemblyStatus.ready,
  List<ComponentItem> components = const [],
  List<String> photoUrls = const [],
}) => SaleItem(
  id: id,
  description: description,
  category: category,
  price: price,
  assemblyStatus: assembly,
  components: components,
  photoUrls: photoUrls,
);

Sale makeSale({
  AssemblyStatus assembly = AssemblyStatus.ready,
  PaymentStatus payment = PaymentStatus.paid,
  PaymentMethod method = PaymentMethod.mbWay,
  ShipmentStatus shipmentStatus = ShipmentStatus.pending,
  DeliveryType delivery = DeliveryType.shipping,
  DateTime? scheduledDate,
  double price = 50.0,
  bool requiresNif = false,
  DateTime? createdAt,
  String category = 'necklace',
  List<SaleItem>? items,
}) => Sale(
  id: 'test',
  buyerId: 'b1',
  buyerName: 'Test Buyer',
  items:
      items ??
      [
        makeSaleItem(
          assembly: assembly,
          category: category,
          price: price,
        ),
      ],
  payment: SalePayment(status: payment, method: method),
  shipment: SaleShipment(type: delivery, status: shipmentStatus),
  requiresNif: requiresNif,
  createdAt: createdAt ?? DateTime(2026),
  scheduledDate: scheduledDate,
);
