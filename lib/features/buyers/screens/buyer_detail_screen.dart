import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/sales_store.dart';
import '../../sales/models/sale.dart';
import '../../sales/repositories/sale_repository.dart';
import '../../sales/screens/sale_detail_screen.dart';
import '../models/buyer.dart';
import '../models/buyer_address.dart';
import '../models/buyer_stats.dart';
import '../repositories/buyer_repository.dart';
import 'buyer_address_form_screen.dart';
import 'buyer_form_screen.dart';

class BuyerDetailScreen extends StatefulWidget {
  final String buyerId;

  const BuyerDetailScreen({super.key, required this.buyerId});

  @override
  State<BuyerDetailScreen> createState() => _BuyerDetailScreenState();
}

class _BuyerDetailScreenState extends State<BuyerDetailScreen> {
  late final BuyerRepository _buyerRepo;
  late final Future<Buyer?> _buyerFuture;

  @override
  void initState() {
    super.initState();
    _buyerRepo = BuyerRepository();
    _buyerFuture = _buyerRepo.getBuyer(widget.buyerId);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: 2,
      child: FutureBuilder<Buyer?>(
        future: _buyerFuture,
        builder: (context, snapshot) {
          final buyer = snapshot.data;
          return Scaffold(
            appBar: AppBar(
              title: Text(buyer?.name ?? s.saleFallbackTitle),
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
                : _BuyerDetailBody(buyer: buyer, buyerRepo: _buyerRepo),
          );
        },
      ),
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
    await _buyerRepo.deleteBuyer(buyer.id);
    if (context.mounted) Navigator.pop(context);
  }
}

class _BuyerDetailBody extends StatelessWidget {
  final Buyer buyer;
  final BuyerRepository buyerRepo;

  const _BuyerDetailBody({required this.buyer, required this.buyerRepo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _InfoSection(buyer: buyer),
        ),
        if (buyer.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: buyer.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _BuyerNotesSection(buyer: buyer, buyerRepo: buyerRepo),
        ),
        TabBar(
          tabs: [
            Tab(text: context.s.purchaseHistory),
            Tab(text: context.s.addresses),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _HistoryTab(buyerId: buyer.id),
              _AddressesTab(
                buyer: buyer,
                buyerRepo: buyerRepo,
                onDelete: (a) => _deleteAddress(context, a),
              ),
            ],
          ),
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

// ── Tabs ──────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final String buyerId;

  const _HistoryTab({required this.buyerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: _BuyerSalesSection(buyerId: buyerId),
    );
  }
}

class _AddressesTab extends StatelessWidget {
  final Buyer buyer;
  final BuyerRepository buyerRepo;
  final void Function(BuyerAddress) onDelete;

  const _AddressesTab({
    required this.buyer,
    required this.buyerRepo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BuyerAddressFormScreen(buyerId: buyer.id),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(s.add),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16, 4, 16, 16 + MediaQuery.of(context).padding.bottom,
            ),
            child: _AddressesList(
              buyerId: buyer.id,
              buyerName: buyer.name,
              buyerRepo: buyerRepo,
              onEdit: (a) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BuyerAddressFormScreen(buyerId: buyer.id, address: a),
                ),
              ),
              onDelete: onDelete,
            ),
          ),
        ),
      ],
    );
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
  DateTime? _filterMonth;
  List<Sale>? _sales;
  BuyerStats? _stats;
  List<DateTime> _months = [];

  @override
  void initState() {
    super.initState();
    SalesStore.state.addListener(_onSalesChanged);
    _onSalesChanged();
  }

  void _onSalesChanged() {
    final all = SalesStore.current;
    final sales = all
        ?.where((s) => s.buyerId == widget.buyerId)
        .toList()
      ?..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _sales = sales;
      _stats = sales != null ? BuyerStats.compute(sales) : null;
      _months = sales == null
          ? []
          : ({
              for (final s in sales)
                DateTime(s.createdAt.year, s.createdAt.month)
            }.toList()
                ..sort((a, b) => b.compareTo(a)));
    });
  }

  @override
  void dispose() {
    SalesStore.state.removeListener(_onSalesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_sales == null) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final allSales = _sales!;

    if (allSales.isEmpty) {
      return Text(
        s.noPurchasesYet,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

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
        _PurchaseSummary(stats: _stats!),
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
              ..._months.map((month) => Padding(
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
  }
}

class _PurchaseSummary extends StatelessWidget {
  final BuyerStats stats;

  const _PurchaseSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

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

// ── Addresses list ────────────────────────────────────────────────────────────

class _AddressesList extends StatefulWidget {
  final String buyerId;
  final String buyerName;
  final BuyerRepository buyerRepo;
  final void Function(BuyerAddress) onEdit;
  final void Function(BuyerAddress) onDelete;

  const _AddressesList({
    required this.buyerId,
    required this.buyerName,
    required this.buyerRepo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AddressesList> createState() => _AddressesListState();
}

class _AddressesListState extends State<_AddressesList> {
  late Stream<List<BuyerAddress>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.buyerRepo.watchAddresses(widget.buyerId);
  }

  @override
  void didUpdateWidget(_AddressesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buyerId != widget.buyerId) {
      _stream = widget.buyerRepo.watchAddresses(widget.buyerId);
    }
  }

  Future<void> _copyAddress(BuildContext context, BuyerAddress address) async {
    final text = address.formattedAddress(widget.buyerName);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.addressCopied)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<BuyerAddress>>(
      stream: _stream,
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
                    onEdit: () => widget.onEdit(a),
                    onDelete: () => widget.onDelete(a),
                    onCopy: () => _copyAddress(context, a),
                  ))
              .toList(),
        );
      },
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
              InkWell(
                onTap: () async {
                  final url = Uri.parse(
                      'https://instagram.com/${buyer.instagramHandle}');
                  try {
                    final launched = await launchUrl(url,
                        mode: LaunchMode.externalApplication);
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(context.s.couldNotOpenInstagram)));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(context.s.couldNotOpenInstagram)));
                    }
                  }
                },
                child: _InfoRow(
                  icon: Icons.alternate_email,
                  text: '@${buyer.instagramHandle}',
                ),
              ),
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

class _BuyerNotesSection extends StatefulWidget {
  final Buyer buyer;
  final BuyerRepository buyerRepo;

  const _BuyerNotesSection({required this.buyer, required this.buyerRepo});

  @override
  State<_BuyerNotesSection> createState() => _BuyerNotesSectionState();
}

class _BuyerNotesSectionState extends State<_BuyerNotesSection> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.buyer.notes ?? '');
  }

  @override
  void didUpdateWidget(_BuyerNotesSection old) {
    super.didUpdateWidget(old);
    if (!_editing && old.buyer.notes != widget.buyer.notes) {
      _controller.text = widget.buyer.notes ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    await widget.buyerRepo
        .updateBuyer(widget.buyer.copyWith(notes: text.isEmpty ? null : text));
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (!_editing && _controller.text.isEmpty) {
      return TextButton.icon(
        onPressed: () => setState(() => _editing = true),
        icon: const Icon(Icons.add),
        label: Text(s.addNotes),
      );
    }

    if (_editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: s.buyerNotesHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _controller.text = widget.buyer.notes ?? '';
                  setState(() => _editing = false);
                },
                child: Text(s.cancel),
              ),
              TextButton(
                onPressed: _save,
                child: Text(s.save),
              ),
            ],
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => setState(() => _editing = true),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.notes,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _controller.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
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
  final VoidCallback onCopy;

  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
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
            PopupMenuItem(value: 'copy', child: Text(s.copy)),
            PopupMenuItem(value: 'edit', child: Text(s.edit)),
            PopupMenuItem(value: 'delete', child: Text(s.delete)),
          ],
          onSelected: (value) {
            if (value == 'copy') onCopy();
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
        ),
      ),
    );
  }
}
