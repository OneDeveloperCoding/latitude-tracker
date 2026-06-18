import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:latitude_tracker/core/constants.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/store/buyers_store.dart';
import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/core/store/store_state.dart';
import 'package:latitude_tracker/core/widgets/store_error_widget.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/repositories/sale_repository.dart';
import 'package:latitude_tracker/features/sales/screens/sale_detail_screen.dart';

class NifPendingScreen extends StatefulWidget {
  const NifPendingScreen({super.key});

  @override
  State<NifPendingScreen> createState() => _NifPendingScreenState();
}

class _NifPendingScreenState extends State<NifPendingScreen> {
  final _saleRepo = SaleRepository();

  List<Sale> _sales = [];
  Map<String, Buyer> _buyersById = {};

  bool get _loading =>
      SalesStore.state.value is StoreLoading ||
      BuyersStore.state.value is StoreLoading;

  @override
  void initState() {
    super.initState();
    SalesStore.state.addListener(_onSalesChanged);
    BuyersStore.state.addListener(_onBuyersChanged);
    _onSalesChanged();
    _onBuyersChanged();
  }

  void _onSalesChanged() {
    final all = SalesStore.current;
    if (all == null) return;
    final filtered = all.where((s) => s.requiresNif).toList()
      ..sort((a, b) {
        if (a.atSubmissionDone == b.atSubmissionDone) return 0;
        return a.atSubmissionDone ? 1 : -1;
      });
    setState(() => _sales = filtered);
  }

  void _onBuyersChanged() {
    setState(() {
      _buyersById = {for (final b in BuyersStore.current ?? <Buyer>[]) b.id: b};
    });
  }

  @override
  void dispose() {
    SalesStore.state.removeListener(_onSalesChanged);
    BuyersStore.state.removeListener(_onBuyersChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateFormat = DateFormat('dd MMM yyyy');

    if (SalesStore.state.value is StoreError ||
        BuyersStore.state.value is StoreError) {
      return Scaffold(
        appBar: AppBar(title: Text(s.nifPendingTitle)),
        body: StoreErrorWidget(
          message: s.errorLoadingData,
          onRetry: () {
            SalesStore.ensureSubscribed();
            BuyersStore.ensureSubscribed();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.nifPendingTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(s.noPendingNif),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                      16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                  children: [
                    Builder(builder: (context) {
                      final pending =
                          _sales.where((s) => !s.atSubmissionDone).length;
                      final filed =
                          _sales.where((s) => s.atSubmissionDone).length;
                      return Text(
                        s.nPending(pending, filed),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      );
                    }),
                    const SizedBox(height: 16),
                    ..._sales.map((sale) {
                      final buyer = _buyersById[sale.buyerId];
                      final filed = sale.atSubmissionDone;
                      return Opacity(
                        opacity: filed ? 0.55 : 1.0,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    SaleDetailScreen(saleId: sale.id),
                              ),
                            ),
                            title: Text(sale.buyerName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sale.items.isEmpty
                                      ? '—'
                                      : sale.items.length == 1
                                          ? sale.items.first.description
                                          : '${sale.items.length} items',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                _NifRow(nif: buyer?.nif),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '€${sale.totalPrice.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                    Text(
                                      dateFormat.format(sale.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    filed
                                        ? Icons.check_circle
                                        : Icons.check_circle_outline,
                                    color: filed
                                        ? Colors.green
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                  tooltip: filed
                                      ? s.markAsPending
                                      : s.markAsFiled,
                                  onPressed: () async {
                                    try {
                                      await _saleRepo.updateSale(
                                        sale.copyWith(
                                            atSubmissionDone: !filed),
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    context.s.errorMsg(e))));
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

class _NifRow extends StatelessWidget {

  const _NifRow({required this.nif});
  final String? nif;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final hasNif = nif != null && nif!.isNotEmpty;
    return Row(
      children: [
        Icon(
          kNifIcon,
          size: 12,
          color: hasNif
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 4),
        Text(
          hasNif ? nif! : s.noNifOnFile,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: hasNif
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
