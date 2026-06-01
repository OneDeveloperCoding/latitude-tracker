import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ArchiveImportScreen extends StatelessWidget {
  final Map<String, dynamic> archive;

  const ArchiveImportScreen({super.key, required this.archive});

  @override
  Widget build(BuildContext context) {
    final year = archive['year'] as int?;
    final exportedAt = archive['exportedAt'] as String?;
    final sales =
        (archive['sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final buyers =
        (archive['buyers'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final totalRevenue = sales.fold<double>(
      0,
      (sum, s) => sum + ((s['price'] as num?)?.toDouble() ?? 0),
    );
    final paidCount = sales
        .where((s) => (s['payment'] as Map?)?['status'] == 'paid')
        .length;

    final currencyFormat =
        NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(year != null ? 'Archive $year' : 'Archive'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Read-only archive',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                  ),
                  if (exportedAt != null)
                    Text(
                      'Exported ${dateFormat.format(DateTime.parse(exportedAt))}',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StatRow(label: 'Total sales', value: '${sales.length}'),
          _StatRow(
              label: 'Paid', value: '$paidCount / ${sales.length}'),
          _StatRow(
              label: 'Total revenue',
              value: currencyFormat.format(totalRevenue)),
          _StatRow(label: 'Buyers', value: '${buyers.length}'),
          const SizedBox(height: 24),
          Text(
            'Sales',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          if (sales.isEmpty)
            const Text('No sales in this archive.')
          else
            ...sales.map((s) => _ArchivedSaleTile(sale: s)),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ArchivedSaleTile extends StatelessWidget {
  final Map<String, dynamic> sale;

  const _ArchivedSaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final price = (sale['price'] as num?)?.toDouble() ?? 0;
    final isPaid = (sale['payment'] as Map?)?['status'] == 'paid';
    final photoUrls =
        (sale['photoUrls'] as List?)?.cast<String>() ?? [];

    final createdAt = sale['createdAt'];
    String dateStr = '';
    if (createdAt is String) {
      dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt));
    } else if (createdAt is Map && createdAt['_seconds'] != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          (createdAt['_seconds'] as int) * 1000);
      dateStr = DateFormat('dd MMM yyyy').format(dt);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(sale['buyerName'] as String? ?? 'Unknown'),
            subtitle: Text(sale['itemDescription'] as String? ?? ''),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('€${price.toStringAsFixed(2)}'),
                Text(
                  isPaid ? 'Paid' : 'Unpaid',
                  style: TextStyle(
                    fontSize: 11,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(dateStr,
                      style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          if (photoUrls.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: photoUrls.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photoUrls[i],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: 64,
                      height: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
