import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../sales/models/sale.dart';
import '../../sales/repositories/sale_repository.dart';
import '../../sales/screens/sale_detail_screen.dart';
import 'buyer_detail_screen.dart';

class UnpaidBalancesScreen extends StatefulWidget {
  const UnpaidBalancesScreen({super.key});

  @override
  State<UnpaidBalancesScreen> createState() => _UnpaidBalancesScreenState();
}

class _UnpaidBalancesScreen {
  final String buyerId;
  final String buyerName;
  final List<Sale> unpaidSales;
  final double totalOwed;

  _UnpaidBalancesScreen({
    required this.buyerId,
    required this.buyerName,
    required this.unpaidSales,
  }) : totalOwed = unpaidSales.fold(0.0, (sum, s) => sum + s.price);
}

class _UnpaidBalancesScreenState extends State<UnpaidBalancesScreen> {
  final _saleRepo = SaleRepository();
  late StreamSubscription<List<Sale>> _salesSub;
  List<_UnpaidBalancesScreen> _groups = [];
  double _grandTotal = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _salesSub = _saleRepo.watchSales().listen((sales) {
      final unpaid =
          sales.where((s) => s.payment.status == PaymentStatus.unpaid).toList();

      final Map<String, List<Sale>> bySeller = {};
      for (final sale in unpaid) {
        bySeller.putIfAbsent(sale.buyerId, () => []).add(sale);
      }

      final groups = bySeller.entries
          .map((e) => _UnpaidBalancesScreen(
                buyerId: e.key,
                buyerName: e.value.first.buyerName,
                unpaidSales: e.value,
              ))
          .toList()
        ..sort((a, b) => b.totalOwed.compareTo(a.totalOwed));

      setState(() {
        _groups = groups;
        _grandTotal = groups.fold(0.0, (sum, g) => sum + g.totalOwed);
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _salesSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unpaid balances'),
      ),
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
                      const Text('All paid up!'),
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
                              'Total outstanding',
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
  final _UnpaidBalancesScreen group;
  final NumberFormat currency;

  const _BuyerDebtCard({required this.group, required this.currency});

  @override
  State<_BuyerDebtCard> createState() => _BuyerDebtCardState();
}

class _BuyerDebtCardState extends State<_BuyerDebtCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
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
                MaterialPageRoute(
                  builder: (_) => BuyerDetailScreen(buyerId: group.buyerId),
                ),
              ),
              child: Text(
                group.buyerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            subtitle: Text(
              '${group.unpaidSales.length} '
              'sale${group.unpaidSales.length == 1 ? '' : 's'}',
            ),
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
                  MaterialPageRoute(
                    builder: (_) => SaleDetailScreen(saleId: sale.id),
                  ),
                ),
                title: Text(
                  sale.itemDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(dateFormat.format(sale.createdAt)),
                trailing: Text(
                  '€${sale.price.toStringAsFixed(2)}',
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
