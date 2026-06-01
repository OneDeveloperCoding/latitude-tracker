import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
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
            title: Text(buyer?.name ?? context.s.saleFallbackTitle),
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
    final s = context.s;
    final sales = await SaleRepository().getSalesForBuyer(buyer.id);
    if (!context.mounted) return;

    final count = sales.length;
    final message = count == 0
        ? s.deleteBuyerNoSalesBody(buyer.name)
        : s.deleteBuyerWithSalesBody(buyer.name, count);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteBuyerTitle(buyer.name)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
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
    final s = context.s;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      children: [
        _InfoSection(buyer: buyer),
        const SizedBox(height: 24),
        Text(s.purchaseHistory, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        _BuyerSalesSection(buyerId: buyer.id),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s.addresses, style: textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BuyerAddressFormScreen(buyerId: buyer.id),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(s.add),
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
                s.noAddressesSaved,
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
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteAddressTitle),
        content: Text(s.deleteAddressConfirm(address.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
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
  final _saleRepo = SaleRepository();
  DateTime? _filterMonth;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return StreamBuilder<List<Sale>>(
      stream: _saleRepo.watchSalesForBuyer(widget.buyerId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(s.errorLoadingSalesMsg(snapshot.error!),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error));
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allSales = snapshot.data!;

        if (allSales.isEmpty) {
          return Text(
            s.noPurchasesYet,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          );
        }

        final months = ({
          for (final sale in allSales)
            DateTime(sale.createdAt.year, sale.createdAt.month)
        }.toList()
              ..sort((a, b) => b.compareTo(a)));

        final filtered = _filterMonth == null
            ? allSales
            : allSales
                .where((sale) =>
                    sale.createdAt.year == _filterMonth!.year &&
                    sale.createdAt.month == _filterMonth!.month)
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
                    label: Text(s.all),
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
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final stats = BuyerStats.compute(sales);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            _StatRow(label: s.totalSalesLabel, value: '${stats.saleCount}'),
            _StatRow(
                label: s.totalPaidLabel,
                value: currency.format(stats.totalPaid)),
            if (stats.unpaidBalance > 0)
              _StatRow(
                label: s.unpaidBalanceLabel,
                value: currency.format(stats.unpaidBalance),
                valueColor: Colors.orange,
              ),
            _StatRow(
              label: s.averageOrderLabel,
              value: currency.format(stats.averageOrderValue),
            ),
            if (stats.lastPurchaseAt != null)
              _StatRow(
                label: s.lastPurchaseLabel,
                value:
                    DateFormat('dd MMM yyyy').format(stats.lastPurchaseAt!),
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
    final s = context.s;
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
              isPaid ? s.paid : s.unpaid,
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
    final s = context.s;
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
              Text(s.noContactDetails),
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
    final s = context.s;
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Text(address.label),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(s.defaultChip),
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
            PopupMenuItem(value: 'edit', child: Text(s.edit)),
            PopupMenuItem(value: 'delete', child: Text(s.delete)),
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
