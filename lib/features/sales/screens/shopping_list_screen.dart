import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../repositories/sale_repository.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping list')),
      body: StreamBuilder<List<Sale>>(
        stream: SaleRepository().watchSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final openSales = (snapshot.data ?? [])
              .where((s) =>
                  s.assemblyStatus != AssemblyStatus.ready &&
                  s.shipment.status != ShipmentStatus.delivered &&
                  s.components.any((c) => !c.isAvailable))
              .toList();

          if (openSales.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text('Nothing left to buy!'),
                ],
              ),
            );
          }

          final totalNeeded = openSales
              .expand((s) => s.components.where((c) => !c.isAvailable))
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '$totalNeeded item${totalNeeded == 1 ? '' : 's'} needed '
                'for ${openSales.length} open sale${openSales.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              ...openSales.map((sale) => _SaleMaterialsCard(sale: sale)),
            ],
          );
        },
      ),
    );
  }
}

class _SaleMaterialsCard extends StatelessWidget {
  final Sale sale;

  const _SaleMaterialsCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final needed = sale.components.where((c) => !c.isAvailable).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sale.buyerName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _AssemblyBadge(status: sale.assemblyStatus),
              ],
            ),
            Text(
              sale.itemDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            ...needed.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text(c.name,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssemblyBadge extends StatelessWidget {
  final AssemblyStatus status;

  const _AssemblyBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AssemblyStatus.notStarted => (Colors.red, 'Not started'),
      AssemblyStatus.waitingForMaterials => (Colors.amber[700]!, 'Waiting for materials'),
      AssemblyStatus.inProgress => (Colors.orange, 'In progress'),
      AssemblyStatus.ready => (Colors.green, 'Ready'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
