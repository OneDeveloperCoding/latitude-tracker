import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

enum _SaleFilter {
  all,
  unpaid,
  nifRequired,
  scheduled,
  pendingShipment,
  shipped,
  pickup,
  assemblyNotReady,
}

extension _SaleFilterLabel on _SaleFilter {
  String get label => switch (this) {
        _SaleFilter.all => 'All',
        _SaleFilter.unpaid => 'Unpaid',
        _SaleFilter.nifRequired => 'NIF required',
        _SaleFilter.scheduled => 'Scheduled',
        _SaleFilter.pendingShipment => 'Pending shipment',
        _SaleFilter.shipped => 'Shipped',
        _SaleFilter.pickup => 'Pickup',
        _SaleFilter.assemblyNotReady => 'Assembly not ready',
      };
}

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final _repository = SaleRepository();
  _SaleFilter _filter = _SaleFilter.all;
  bool _timelineView = false;

  List<Sale> _applyFilter(List<Sale> sales) => switch (_filter) {
        _SaleFilter.all => sales,
        _SaleFilter.unpaid =>
          sales.where((s) => s.payment.status == PaymentStatus.unpaid).toList(),
        _SaleFilter.nifRequired =>
          sales.where((s) => s.requiresNif).toList(),
        _SaleFilter.scheduled =>
          sales.where((s) => s.scheduledDate != null).toList(),
        _SaleFilter.pendingShipment => sales
            .where((s) =>
                s.shipment.type == DeliveryType.shipping &&
                s.shipment.status == ShipmentStatus.pending)
            .toList(),
        _SaleFilter.shipped => sales
            .where((s) => s.shipment.status == ShipmentStatus.shipped)
            .toList(),
        _SaleFilter.pickup => sales
            .where((s) => s.shipment.type == DeliveryType.pickup)
            .toList(),
        _SaleFilter.assemblyNotReady => sales
            .where((s) => s.assemblyStatus != AssemblyStatus.ready)
            .toList(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: Icon(_timelineView ? Icons.list : Icons.calendar_view_week),
            tooltip: _timelineView ? 'List view' : 'Timeline view',
            onPressed: () => setState(() => _timelineView = !_timelineView),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewSaleScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _SaleFilter.values
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f.label),
                          selected: _filter == f,
                          onSelected: (_) =>
                              setState(() => _filter = f),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Sale>>(
              stream: _repository.watchSales(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final sales = _applyFilter(snapshot.data ?? []);
                if (sales.isEmpty) {
                  return const Center(child: Text('No sales found.'));
                }
                return _timelineView
                    ? _TimelineView(sales: sales)
                    : _ListView(sales: sales);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<Sale> sales;

  const _ListView({required this.sales});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: sales.length,
      itemBuilder: (context, index) => _SaleTile(sale: sales[index]),
    );
  }
}

class _TimelineView extends StatelessWidget {
  final List<Sale> sales;

  const _TimelineView({required this.sales});

  Map<String, List<Sale>> _groupByWeek(List<Sale> sales) {
    final now = DateTime.now();
    final Map<String, List<Sale>> groups = {};
    // Preserve order: Overdue → This week → Next week → Later → past months
    const order = ['Overdue', 'This week', 'Next week', 'Later'];

    for (final sale in sales) {
      final label = _weekLabel(sale, now);
      groups.putIfAbsent(label, () => []).add(sale);
    }

    final sorted = <String, List<Sale>>{};
    for (final key in order) {
      if (groups.containsKey(key)) sorted[key] = groups[key]!;
    }
    for (final key in groups.keys) {
      if (!order.contains(key)) sorted[key] = groups[key]!;
    }
    return sorted;
  }

  String _weekLabel(Sale sale, DateTime now) {
    final relevantDate = sale.scheduledDate ?? sale.createdAt;
    final startOfThisWeek =
        DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
    final startOfNextWeek =
        startOfThisWeek.add(const Duration(days: 7));
    final endOfNextWeek =
        startOfNextWeek.add(const Duration(days: 7));

    // Overdue: has a scheduled date in the past and not yet delivered
    if (sale.scheduledDate != null &&
        sale.scheduledDate!.isBefore(startOfThisWeek) &&
        sale.shipment.status != ShipmentStatus.delivered) {
      return 'Overdue';
    }
    if (relevantDate.isAfter(
        startOfThisWeek.subtract(const Duration(seconds: 1))) &&
        relevantDate.isBefore(startOfNextWeek)) {
      return 'This week';
    }
    if (relevantDate.isAfter(
        startOfNextWeek.subtract(const Duration(seconds: 1))) &&
        relevantDate.isBefore(endOfNextWeek)) {
      return 'Next week';
    }
    if (relevantDate.isAfter(endOfNextWeek)) {
      return 'Later';
    }
    return DateFormat('MMMM yyyy').format(relevantDate);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByWeek(sales);
    final keys = groups.keys.toList();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final label = keys[index];
        final groupSales = groups[label]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...groupSales.map((s) => _SaleTile(sale: s)),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;

  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');
    final isPickup = sale.shipment.type == DeliveryType.pickup;

    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(sale.buyerName, overflow: TextOverflow.ellipsis),
          ),
          if (sale.requiresNif) ...[
            const SizedBox(width: 4),
            _MiniChip(label: 'NIF', color: Colors.purple),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sale.itemDescription,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sale.scheduledDate != null)
            Text(
              '📅 ${DateFormat('dd MMM').format(sale.scheduledDate!)}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
        ],
      ),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '€${sale.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            dateFormat.format(sale.createdAt),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _MiniChip(
            label:
                sale.payment.status == PaymentStatus.paid ? 'Paid' : 'Unpaid',
            color: sale.payment.status == PaymentStatus.paid
                ? Colors.green
                : Colors.orange,
          ),
          const SizedBox(height: 4),
          _MiniChip(
            label: isPickup ? '📦 Pickup' : sale.shipment.status.label,
            color: isPickup
                ? Colors.teal
                : sale.shipment.status == ShipmentStatus.delivered
                    ? Colors.green
                    : sale.shipment.status == ShipmentStatus.shipped
                        ? Colors.blue
                        : Colors.grey,
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SaleDetailScreen(saleId: sale.id),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}
