import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/url_launch_service.dart';
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
  late final Stream<Buyer?> _buyerStream;

  @override
  void initState() {
    super.initState();
    _buyerRepo = BuyerRepository();
    _buyerStream = _buyerRepo.watchBuyer(widget.buyerId);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return StreamBuilder<Buyer?>(
      stream: _buyerStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(s.saleFallbackTitle)),
            body: Center(child: Text(s.errorLoadingDetail)),
          );
        }

        final buyer = snapshot.data;

        if (buyer == null) {
          if (snapshot.connectionState != ConnectionState.waiting) {
            // Buyer deleted on another device — navigate back after this frame.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) Navigator.of(context).pop();
            });
          }
          return Scaffold(
            appBar: AppBar(title: Text(s.saleFallbackTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(buyer.name),
              actions: [
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
            ),
            body: _BuyerDetailBody(buyer: buyer, buyerRepo: _buyerRepo),
          ),
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
    try {
      await _buyerRepo.deleteBuyer(buyer.id);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorDeletingBuyerMsg(e))),
        );
      }
    }
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
    if (confirmed != true || !context.mounted) return;
    try {
      await buyerRepo.deleteAddress(buyer.id, address.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errGeneric)),
        );
      }
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
  bool _showAll = false;
  int? _selectedYear;
  DateTime? _selectedMonth;

  List<Sale>? _sales;
  BuyerStats? _stats;
  // Unique year+month combinations derived from sales, sorted descending.
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

  List<Sale> _applyFilter(List<Sale> all) {
    if (_showAll) return all;
    if (_selectedMonth != null) {
      return all
          .where((s) =>
              s.createdAt.year == _selectedMonth!.year &&
              s.createdAt.month == _selectedMonth!.month)
          .toList();
    }
    if (_selectedYear != null) {
      return all.where((s) => s.createdAt.year == _selectedYear).toList();
    }
    // Default: last 3 calendar months (current month + 2 prior).
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month - 2);
    return all
        .where((s) => !DateTime(s.createdAt.year, s.createdAt.month)
            .isBefore(cutoff))
        .toList();
  }

  List<int> get _years =>
      _months.map((m) => m.year).toSet().toList()..sort((a, b) => b - a);

  List<DateTime> _monthsForYear(int year) =>
      _months.where((m) => m.year == year).toList();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }

    final filtered = _applyFilter(allSales);
    final isDefaultView = !_showAll && _selectedYear == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PurchaseSummary(stats: _stats!),
        const SizedBox(height: 12),
        // Year row: "All" chip + one chip per year.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text(s.all),
                selected: _showAll,
                onSelected: (_) => setState(() {
                  _showAll = true;
                  _selectedYear = null;
                  _selectedMonth = null;
                }),
              ),
              ..._years.map((year) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text('$year'),
                      selected: !_showAll && _selectedYear == year,
                      onSelected: (_) => setState(() {
                        _showAll = false;
                        _selectedYear = year;
                        _selectedMonth = null;
                      }),
                    ),
                  )),
            ],
          ),
        ),
        // Month row: only visible when a year is selected.
        if (_selectedYear != null) ...[
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _monthsForYear(_selectedYear!).map((month) {
                final isSelected = _selectedMonth == month;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(DateFormat('MMM').format(month)),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      _selectedMonth = isSelected ? null : month;
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        // Scope hint shown in default view.
        if (isDefaultView) ...[
          const SizedBox(height: 4),
          Text(
            s.last3Months,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
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
              label: s.averageSaleLabel,
              value: currency.format(stats.averageSaleValue),
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
        title: Text(
          sale.items.isEmpty
              ? '—'
              : sale.items.length == 1
                  ? sale.items.first.description
                  : sale.items.map((i) => i.description).join(', '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(DateFormat('dd MMM yyyy').format(sale.createdAt)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sale.notes?.isNotEmpty == true) ...[
              InkWell(
                onTap: () => _showNotePreview(context, sale.notes!),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('€${sale.totalPrice.toStringAsFixed(2)}'),
                Text(
                  isPaid ? s.paid : s.unpaid,
                  style: TextStyle(
                    fontSize: 11,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
              ],
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

void _showNotePreview(BuildContext context, String notes) {
  final s = context.s;
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sticky_note_2_outlined,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(s.sectionNotes,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ),
  );
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

  Future<void> _openMaps(BuildContext context, BuyerAddress address) =>
      launchMapsUrl(context, address.mapsUri);

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
        if (snapshot.hasError) {
          return Center(child: Text(s.errorLoadingDetail));
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
                    onOpenMaps: a.hasMapsAddress
                        ? () => _openMaps(context, a)
                        : null,
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
              _InfoRow(icon: kNifIcon, text: 'NIF: ${buyer.nif}'),
            if (buyer.instagramHandle == null &&
                buyer.phone == null &&
                buyer.nif == null)
              Text(s.noContactDetails),
            if (buyer.tags.isNotEmpty || (buyer.notes?.isNotEmpty ?? false)) ...[
              const Divider(height: 24),
              if (buyer.tags.isNotEmpty)
                Wrap(
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
              if (buyer.notes?.isNotEmpty ?? false) ...[
                if (buyer.tags.isNotEmpty) const SizedBox(height: 8),
                Row(
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
                        buyer.notes!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
  final VoidCallback? onOpenMaps;

  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    this.onOpenMaps,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onOpenMaps != null)
              IconButton(
                icon: const Icon(Icons.map),
                onPressed: onOpenMaps,
                tooltip: s.openInMaps,
              ),
            PopupMenuButton(
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
          ],
        ),
      ),
    );
  }
}
