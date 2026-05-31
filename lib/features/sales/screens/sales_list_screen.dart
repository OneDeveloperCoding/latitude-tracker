import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

enum _SaleFilter { all, unpaid, pendingShipment, assemblyNotReady }

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final _repository = SaleRepository();
  _SaleFilter _filter = _SaleFilter.all;

  List<Sale> _applyFilter(List<Sale> sales) => switch (_filter) {
        _SaleFilter.all => sales,
        _SaleFilter.unpaid =>
          sales.where((s) => s.payment.status == PaymentStatus.unpaid).toList(),
        _SaleFilter.pendingShipment => sales
            .where((s) => s.shipment.status != ShipmentStatus.delivered)
            .toList(),
        _SaleFilter.assemblyNotReady => sales
            .where((s) => s.assemblyStatus != AssemblyStatus.ready)
            .toList(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
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
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == _SaleFilter.all,
                  onSelected: () => setState(() => _filter = _SaleFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Unpaid',
                  selected: _filter == _SaleFilter.unpaid,
                  onSelected: () =>
                      setState(() => _filter = _SaleFilter.unpaid),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending shipment',
                  selected: _filter == _SaleFilter.pendingShipment,
                  onSelected: () =>
                      setState(() => _filter = _SaleFilter.pendingShipment),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Assembly not ready',
                  selected: _filter == _SaleFilter.assemblyNotReady,
                  onSelected: () =>
                      setState(() => _filter = _SaleFilter.assemblyNotReady),
                ),
              ],
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
                return ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) =>
                      _SaleTile(sale: sales[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;

  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');

    return ListTile(
      title: Text(sale.buyerName),
      subtitle: Text(
        sale.itemDescription,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
            label: sale.payment.status == PaymentStatus.paid ? 'Paid' : 'Unpaid',
            color: sale.payment.status == PaymentStatus.paid
                ? Colors.green
                : Colors.orange,
          ),
          const SizedBox(height: 4),
          _MiniChip(
            label: sale.shipment.status.label,
            color: sale.shipment.status == ShipmentStatus.delivered
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
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
