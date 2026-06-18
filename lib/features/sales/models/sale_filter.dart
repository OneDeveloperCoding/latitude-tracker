import 'package:latitude_tracker/features/sales/models/sale.dart';

/// Returns true if [sale] passes every filter in [filters] AND the optional
/// date range. AND logic — the sale must match all active filters.
/// An empty [filters] set means no filter constraint.
/// [dateFrom]/[dateTo] are inclusive date-only boundaries (time part ignored).
bool testSaleFilters(
  Sale sale,
  Set<SaleFilter> filters, {
  DateTime? dateFrom,
  DateTime? dateTo,
  DateTime? now,
}) {
  if (dateFrom != null) {
    final d = sale.createdAt;
    final day = DateTime(d.year, d.month, d.day);
    if (day.isBefore(dateFrom)) return false;
  }
  if (dateTo != null) {
    final d = sale.createdAt;
    final day = DateTime(d.year, d.month, d.day);
    if (day.isAfter(dateTo)) return false;
  }
  if (filters.isEmpty) return true;
  final today = now ?? DateTime.now();
  return filters.every((f) => f.test(sale, now: today));
}

enum SaleFilter {
  all,
  unpaid,
  nifRequired,
  scheduled,
  pendingShipment,
  shipped,
  pickup,
  handDelivery,
  assemblyNotReady,
  overdue,
  upcomingScheduled,
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
        (sale.shipment.type == DeliveryType.shipping ||
                sale.shipment.type == DeliveryType.handDelivery) &&
            sale.shipment.status == ShipmentStatus.pending,
      SaleFilter.shipped => sale.shipment.status == ShipmentStatus.shipped,
      SaleFilter.pickup => sale.shipment.type == DeliveryType.pickup,
      SaleFilter.handDelivery =>
        sale.shipment.type == DeliveryType.handDelivery,
      SaleFilter.assemblyNotReady =>
        sale.derivedAssemblyStatus != AssemblyStatus.ready,
      SaleFilter.overdue =>
        sale.scheduledDate != null &&
            sale.scheduledDate!.isBefore(startOfToday) &&
            sale.shipment.status != ShipmentStatus.delivered,
      SaleFilter.upcomingScheduled =>
        sale.scheduledDate != null &&
            !sale.scheduledDate!.isBefore(startOfToday) &&
            sale.shipment.status != ShipmentStatus.delivered,
    };
  }
}
