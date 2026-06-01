import 'sale.dart';

enum SaleFilter {
  all,
  unpaid,
  nifRequired,
  scheduled,
  pendingShipment,
  shipped,
  pickup,
  assemblyNotReady,
  overdue,
}

extension SaleFilterLabel on SaleFilter {
  String get label => switch (this) {
        SaleFilter.all => 'All',
        SaleFilter.unpaid => 'Unpaid',
        SaleFilter.nifRequired => 'NIF required',
        SaleFilter.scheduled => 'Scheduled',
        SaleFilter.pendingShipment => 'Pending shipment',
        SaleFilter.shipped => 'Shipped',
        SaleFilter.pickup => 'Pickup',
        SaleFilter.assemblyNotReady => 'Assembly not ready',
        SaleFilter.overdue => 'Overdue',
      };
}

extension SaleFilterTest on SaleFilter {
  // [now] is injectable so callers (e.g. DashboardStats) can pass a fixed
  // reference point rather than calling DateTime.now() repeatedly per-sale.
  bool test(Sale sale, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return switch (this) {
      SaleFilter.all => true,
      SaleFilter.unpaid => sale.payment.status == PaymentStatus.unpaid,
      SaleFilter.nifRequired => sale.requiresNif,
      SaleFilter.scheduled => sale.scheduledDate != null,
      SaleFilter.pendingShipment =>
        sale.shipment.type == DeliveryType.shipping &&
            sale.shipment.status == ShipmentStatus.pending,
      SaleFilter.shipped =>
        sale.shipment.status == ShipmentStatus.shipped,
      SaleFilter.pickup => sale.shipment.type == DeliveryType.pickup,
      SaleFilter.assemblyNotReady =>
        sale.assemblyStatus != AssemblyStatus.ready,
      SaleFilter.overdue =>
        sale.scheduledDate != null &&
            sale.scheduledDate!.isBefore(startOfToday) &&
            sale.shipment.status != ShipmentStatus.delivered,
    };
  }
}
