import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sale_grouper.dart';
import 'package:latitude_tracker/features/sales/widgets/photo_grid.dart' show PhotoViewer;

class SalePickerScreen extends StatefulWidget {

  const SalePickerScreen({
    required this.buyerId, required this.buyerName, super.key,
  });
  final String buyerId;
  final String buyerName;

  @override
  State<SalePickerScreen> createState() => _SalePickerScreenState();
}

class _SalePickerScreenState extends State<SalePickerScreen> {
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    SalesStore.state.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    SalesStore.state.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  List<Sale> get _filteredSales {
    final all = SalesStore.current ?? [];
    final byBuyer = all
        .where((s) => s.buyerId == widget.buyerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_showAll) return byBuyer;
    final year = DateTime.now().year;
    return byBuyer.where((s) => s.createdAt.year == year).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final sales = _filteredSales;
    return Scaffold(
      appBar: AppBar(title: Text(widget.buyerName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  label: Text(s.allYears),
                  selected: _showAll,
                  onSelected: (v) => setState(() => _showAll = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: sales.isEmpty
                ? _buildEmpty(s)
                : _showAll
                    ? _buildGroupedList(sales)
                    : _buildFlatList(sales),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppStrings s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.noSalesFound),
          if (!_showAll) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text(s.allYears),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlatList(List<Sale> sales) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sales.length,
      itemBuilder: (_, i) => _SalePickerCard(
        sale: sales[i],
        onTap: () => Navigator.pop(context, sales[i]),
      ),
    );
  }

  Widget _buildGroupedList(List<Sale> sales) {
    final entries = SaleGrouper.byCreatedMonth(sales).entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...entry.value.map((sale) => _SalePickerCard(
                  sale: sale,
                  onTap: () => Navigator.pop(context, sale),
                )),
          ],
        );
      },
    );
  }
}

class _SalePickerCard extends StatelessWidget {

  const _SalePickerCard({required this.sale, required this.onTap});
  final Sale sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(sale.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '€${sale.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...sale.items.map((item) => _ItemRow(item: item)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {

  const _ItemRow({required this.item});
  final SaleItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          _Thumbnail(item: item),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${item.category} · ${item.description}',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {

  const _Thumbnail({required this.item});
  final SaleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (item.photoUrls.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PhotoViewer(urls: item.photoUrls, initialIndex: 0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          item.photoUrls.first,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          cacheWidth: (48 * MediaQuery.devicePixelRatioOf(context)).round(),
          cacheHeight: (48 * MediaQuery.devicePixelRatioOf(context)).round(),
          errorBuilder: (context, error, _) => Container(
            width: 48,
            height: 48,
            color: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image_outlined,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
