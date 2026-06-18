import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency.dart';

/// One contributing SaleItem for an [AggregatedComponent].
class ComponentSource {
  const ComponentSource({
    required this.sale,
    required this.item,
    required this.component,
  });
  final Sale sale;
  final SaleItem item;
  final ComponentItem component;
}

/// A component name merged across all open SaleItems, with quantities summed.
class AggregatedComponent {
  const AggregatedComponent({
    required this.name,
    required this.totalQuantity,
    required this.worstUrgency,
    required this.sources,
  });
  final String name;
  final int totalQuantity;
  final UrgencyLevel worstUrgency;
  final List<ComponentSource> sources;
}

/// Groups unacquired [ComponentItem]s by name (case-insensitive) across all
/// open Sales and sums their quantities.
///
/// "Open" means not yet delivered and not yet fully assembled.
/// Rows are sorted by worst-case urgency (overdue → this week → none).
///
/// Pass [now] to override the current time — useful in tests.
List<AggregatedComponent> aggregateShoppingList(
  List<Sale> sales, {
  DateTime? now,
}) {
  final byKey = <String, AggregatedComponent>{};

  for (final sale in sales) {
    if (sale.shipment.status == ShipmentStatus.delivered) continue;
    if (sale.derivedAssemblyStatus == AssemblyStatus.ready) continue;
    final urgency = sale.urgencyLevel(now: now);

    for (final item in sale.items) {
      if (item.assemblyStatus == AssemblyStatus.ready) continue;
      for (final c in item.components.where((c) => !c.isAvailable)) {
        final key = c.name.toLowerCase().trim();
        final source = ComponentSource(sale: sale, item: item, component: c);
        final existing = byKey[key];
        byKey[key] = existing == null
            ? AggregatedComponent(
                name: c.name,
                totalQuantity: c.quantity,
                worstUrgency: urgency,
                sources: [source],
              )
            : AggregatedComponent(
                name: existing.name,
                totalQuantity: existing.totalQuantity + c.quantity,
                worstUrgency: _worstUrgency(existing.worstUrgency, urgency),
                sources: [...existing.sources, source],
              );
      }
    }
  }

  return byKey.values.toList()
    ..sort((a, b) => a.worstUrgency.index.compareTo(b.worstUrgency.index));
}

UrgencyLevel _worstUrgency(UrgencyLevel a, UrgencyLevel b) =>
    a.index <= b.index ? a : b;
