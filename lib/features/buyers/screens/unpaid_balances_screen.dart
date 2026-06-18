import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/core/store/store_state.dart';
import 'package:latitude_tracker/core/widgets/store_error_widget.dart';
import 'package:latitude_tracker/features/buyers/screens/buyer_detail_screen.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/screens/sale_detail_screen.dart';
import 'package:latitude_tracker/features/sales/services/sale_grouper.dart';

class UnpaidBalancesScreen extends StatefulWidget {
  const UnpaidBalancesScreen({super.key});

  @override
  State<UnpaidBalancesScreen> createState() => _UnpaidBalancesScreenState();
}

class _UnpaidBalancesGroup {

  _UnpaidBalancesGroup({
    required this.buyerId,
    required this.buyerName,
    required this.unpaidSales,
  }) : totalOwed = unpaidSales.fold(0, (sum, s) => sum + s.totalPrice);
  final String buyerId;
  final String buyerName;
  final List<Sale> unpaidSales;
  final double totalOwed;
}

class _UnpaidBalancesScreenState extends State<UnpaidBalancesScreen> {
  List<_UnpaidBalancesGroup> _groups = [];
  double _grandTotal = 0;

  bool get _loading => SalesStore.state.value is StoreLoading;

  @override
  void initState() {
    super.initState();
    SalesStore.state.addListener(_onSalesChanged);
    _onSalesChanged();
  }

  void _onSalesChanged() {
    final all = SalesStore.current;
    if (all == null) return;
    final unpaid =
        all.where((s) => s.payment.status == PaymentStatus.unpaid).toList();

    final groups = SaleGrouper.byBuyerId(unpaid).entries
        .map((e) => _UnpaidBalancesGroup(
              buyerId: e.key,
              buyerName: e.value.first.buyerName,
              unpaidSales: e.value,
            ))
        .toList()
      ..sort((a, b) => b.totalOwed.compareTo(a.totalOwed));

    setState(() {
      _groups = groups;
      _grandTotal = groups.fold(0, (sum, g) => sum + g.totalOwed);
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
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    if (SalesStore.state.value is StoreError) {
      return Scaffold(
        appBar: AppBar(title: Text(s.unpaid)),
        body: StoreErrorWidget(
          message: s.errorLoadingSales,
          onRetry: SalesStore.ensureSubscribed,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.unpaid)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(s.allPaid),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                      16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                  children: [
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.totalOutstanding,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                            ),
                            Text(
                              currency.format(_grandTotal),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._groups.map((group) => _BuyerDebtCard(
                          group: group,
                          currency: currency,
                        )),
                  ],
                ),
    );
  }
}

class _BuyerDebtCard extends StatefulWidget {

  const _BuyerDebtCard({required this.group, required this.currency});
  final _UnpaidBalancesGroup group;
  final NumberFormat currency;

  @override
  State<_BuyerDebtCard> createState() => _BuyerDebtCardState();
}

class _BuyerDebtCardState extends State<_BuyerDebtCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final group = widget.group;
    final dateFormat = DateFormat('dd MMM');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            title: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BuyerDetailScreen(buyerId: group.buyerId),
                ),
              ),
              child: Text(
                group.buyerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            subtitle: Text(s.nSales(group.unpaidSales.length)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.currency.format(group.totalOwed),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...group.unpaidSales.map(
              (sale) => ListTile(
                dense: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SaleDetailScreen(saleId: sale.id),
                  ),
                ),
                title: Text(
                  sale.items.isEmpty
                      ? '—'
                      : sale.items.length == 1
                          ? sale.items.first.description
                          : '${sale.items.length} items',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(dateFormat.format(sale.createdAt)),
                trailing: Text(
                  '€${sale.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
