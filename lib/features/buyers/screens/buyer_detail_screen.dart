import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../sales/models/sale.dart';
import '../../sales/repositories/sale_repository.dart';
import '../../sales/screens/sale_detail_screen.dart';
import '../models/buyer.dart';
import '../models/buyer_address.dart';
import '../models/buyer_stats.dart';
import '../repositories/buyer_repository.dart';
import 'buyer_address_form_screen.dart';
import 'buyer_form_screen.dart';

class BuyerDetailScreen extends StatelessWidget {
  final String buyerId;

  const BuyerDetailScreen({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    final buyerRepo = BuyerRepository();

    return FutureBuilder<Buyer?>(
      future: buyerRepo.getBuyer(buyerId),
      builder: (context, snapshot) {
        final buyer = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(buyer?.name ?? 'Buyer'),
            actions: [
              if (buyer != null) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BuyerFormScreen(buyer: buyer)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, buyer),
                ),
              ],
            ],
          ),
          body: buyer == null
              ? const Center(child: CircularProgressIndicator())
              : _BuyerDetailBody(buyer: buyer, buyerRepo: buyerRepo),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Buyer buyer) async {
    final sales = await SaleRepository().getSalesForBuyer(buyer.id);
    if (!context.mounted) return;

    final count = sales.length;
    final message = count == 0
        ? '${buyer.name} will be permanently removed.'
        : '${buyer.name} has $count sale${count == 1 ? '' : 's'} on record. '
            'Their sales history will be kept, but the buyer profile and all '
            'saved addresses will be removed.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${buyer.name}?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await BuyerRepository().deleteBuyer(buyer.id);
    if (context.mounted) Navigator.pop(context);
  }
}

class _BuyerDetailBody extends StatelessWidget {
  final Buyer buyer;
  final BuyerRepository buyerRepo;

  const _BuyerDetailBody({required this.buyer, required this.buyerRepo});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoSection(buyer: buyer),
        const SizedBox(height: 24),
        Text('Purchase history', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        _BuyerSalesSection(buyerId: buyer.id),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Addresses', style: textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BuyerAddressFormScreen(buyerId: buyer.id),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<BuyerAddress>>(
          stream: buyerRepo.watchAddresses(buyer.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final addresses = snapshot.data ?? [];
            if (addresses.isEmpty) {
              return Text(
                'No addresses saved.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              );
            }
            return Column(
              children: addresses
                  .map((a) => _AddressTile(
                        address: a,
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BuyerAddressFormScreen(
                                buyerId: buyer.id, address: a),
                          ),
                        ),
                        onDelete: () => _deleteAddress(context, a),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _deleteAddress(
      BuildContext context, BuyerAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove "${address.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await buyerRepo.deleteAddress(buyer.id, address.id);
    }
  }
}

// ── Purchase history ──────────────────────────────────────────────────────────

class _BuyerSalesSection extends StatefulWidget {
  final String buyerId;

  const _BuyerSalesSection({required this.buyerId});

  @override
  State<_BuyerSalesSection> createState() => _BuyerSalesSectionState();
}

class _BuyerSalesSectionState extends State<_BuyerSalesSection> {
  late final Future<List<Sale>> _salesFuture;
  DateTime? _filterMonth;

  @override
  void initState() {
    super.initState();
    _salesFuture = SaleRepository().getSalesForBuyer(widget.buyerId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Sale>>(
      future: _salesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allSales = List<Sale>.from(snapshot.data!)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (allSales.isEmpty) {
          return Text(
            'No purchases yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          );
        }

        final months = ({
          for (final s in allSales)
            DateTime(s.createdAt.year, s.createdAt.month)
        }.toList()
              ..sort((a, b) => b.compareTo(a)));

        final filtered = _filterMonth == null
            ? allSales
            : allSales
                .where((s) =>
                    s.createdAt.year == _filterMonth!.year &&
                    s.createdAt.month == _filterMonth!.month)
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PurchaseSummary(sales: allSales),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterMonth == null,
                    onSelected: (_) => setState(() => _filterMonth = null),
                  ),
                  ...months.map((month) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(DateFormat('MMM yyyy').format(month)),
                          selected: _filterMonth == month,
                          onSelected: (_) =>
                              setState(() => _filterMonth = month),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...filtered.map((sale) => _SaleTile(sale: sale)),
          ],
        );
      },
    );
  }
}

class _PurchaseSummary extends StatelessWidget {
  final List<Sale> sales;

  const _PurchaseSummary({required this.sales});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final stats = BuyerStats.compute(sales);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            _StatRow(label: 'Total sales', value: '${stats.saleCount}'),
            _StatRow(label: 'Total paid', value: currency.format(stats.totalPaid)),
            if (stats.unpaidBalance > 0)
              _StatRow(
                label: 'Unpaid balance',
                value: currency.format(stats.unpaidBalance),
                valueColor: Colors.orange,
              ),
            _StatRow(
              label: 'Average order',
              value: currency.format(stats.averageOrderValue),
            ),
            if (stats.lastPurchaseAt != null)
              _StatRow(
                label: 'Last purchase',
                value: DateFormat('dd MMM yyyy').format(stats.lastPurchaseAt!),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: valueColor,
        ),
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;

  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final isPaid = sale.payment.status == PaymentStatus.paid;

    return Card(
      child: ListTile(
        title: Text(sale.itemDescription),
        subtitle: Text(DateFormat('dd MMM yyyy').format(sale.createdAt)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('€${sale.price.toStringAsFixed(2)}'),
            Text(
              isPaid ? 'Paid' : 'Unpaid',
              style: TextStyle(
                fontSize: 11,
                color: isPaid ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SaleDetailScreen(saleId: sale.id)),
        ),
      ),
    );
  }
}

// ── Info section ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final Buyer buyer;

  const _InfoSection({required this.buyer});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (buyer.instagramHandle != null)
              _InfoRow(
                  icon: Icons.alternate_email,
                  text: '@${buyer.instagramHandle}'),
            if (buyer.phone != null)
              _InfoRow(icon: Icons.phone, text: buyer.phone!),
            if (buyer.nif != null)
              _InfoRow(icon: Icons.badge, text: 'NIF: ${buyer.nif}'),
            if (buyer.instagramHandle == null &&
                buyer.phone == null &&
                buyer.nif == null)
              const Text('No contact details saved.'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

// ── Address tile ──────────────────────────────────────────────────────────────

class _AddressTile extends StatelessWidget {
  final BuyerAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Text(address.label),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Chip(
                label: const Text('Default'),
                padding: EdgeInsets.zero,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${address.street}\n${address.postalCode} ${address.city}, ${address.country}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
        ),
      ),
    );
  }
}
