import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../buyers/models/buyer.dart';
import '../../buyers/repositories/buyer_repository.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import 'sale_detail_screen.dart';

class NifPendingScreen extends StatefulWidget {
  const NifPendingScreen({super.key});

  @override
  State<NifPendingScreen> createState() => _NifPendingScreenState();
}

class _NifPendingScreenState extends State<NifPendingScreen> {
  final _saleRepo = SaleRepository();
  final _buyerRepo = BuyerRepository();

  late StreamSubscription<List<Sale>> _salesSub;
  late StreamSubscription<List<Buyer>> _buyersSub;

  List<Sale> _sales = [];
  Map<String, Buyer> _buyersById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _salesSub = _saleRepo.watchSales().listen((sales) {
      final filtered = sales.where((s) => s.requiresNif).toList()
        ..sort((a, b) {
          if (a.atSubmissionDone == b.atSubmissionDone) return 0;
          return a.atSubmissionDone ? 1 : -1;
        });
      setState(() {
        _sales = filtered;
        _loading = false;
      });
    });
    _buyersSub = _buyerRepo.watchBuyers().listen((buyers) {
      setState(() => _buyersById = {for (final b in buyers) b.id: b});
    });
  }

  @override
  void dispose() {
    _salesSub.cancel();
    _buyersSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('NIF receipts pending'),
      ),
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
                      const Text('No pending NIF receipts.'),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Builder(builder: (context) {
                      final pending =
                          _sales.where((s) => !s.atSubmissionDone).length;
                      final filed =
                          _sales.where((s) => s.atSubmissionDone).length;
                      return Text(
                        '$pending pending · $filed filed',
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
                              MaterialPageRoute(
                                builder: (_) =>
                                    SaleDetailScreen(saleId: sale.id),
                              ),
                            ),
                            title: Text(sale.buyerName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sale.itemDescription,
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
                                      '€${sale.price.toStringAsFixed(2)}',
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
                                      ? 'Mark as pending'
                                      : 'Mark as filed',
                                  onPressed: () => _saleRepo.updateSale(
                                    sale.copyWith(
                                        atSubmissionDone: !filed),
                                  ),
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
  final String? nif;

  const _NifRow({required this.nif});

  @override
  Widget build(BuildContext context) {
    final hasNif = nif != null && nif!.isNotEmpty;
    return Row(
      children: [
        Icon(
          Icons.badge_outlined,
          size: 12,
          color: hasNif
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 4),
        Text(
          hasNif ? nif! : 'No NIF on file',
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
