import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/services/auth_revoked_exception.dart';
import 'package:latitude_tracker/features/settings/screens/archive_analytics_screen.dart';
import 'package:latitude_tracker/features/settings/services/archive_service.dart';

class ArchiveImportScreen extends StatefulWidget {
  const ArchiveImportScreen({required this.archive, super.key});
  final Map<String, dynamic> archive;

  @override
  State<ArchiveImportScreen> createState() => _ArchiveImportScreenState();
}

class _ArchiveImportScreenState extends State<ArchiveImportScreen> {
  ImportResult? _lastResult;
  bool _importing = false;

  List<Map<String, dynamic>> get _sales =>
      (widget.archive['sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  List<Map<String, dynamic>> get _buyers =>
      (widget.archive['buyers'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  Future<void> _confirmImport() async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.archiveImportTitle),
        content: Text(s.archiveImportBody(_sales.length, _buyers.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.archiveImportAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    _runImport();
  }

  Future<void> _runImport() async {
    setState(() => _importing = true);

    try {
      final result = await ArchiveService().importArchive(widget.archive);
      if (!mounted) return;
      setState(() {
        _lastResult = result;
        _importing = false;
      });
      _showResult(result);
    } catch (e) {
      if (e is AuthRevokedException) {
        FirebaseAuth.instance.signOut();
        return;
      }
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.importFailedMsg(e))),
      );
    }
  }

  void _showResult(ImportResult result) {
    final s = context.s;
    final parts = <String>[];
    if (result.salesImported > 0) {
      parts.add(s.archiveSalesImportedMsg(result.salesImported));
    }
    if (result.buyersImported > 0) {
      parts.add(s.archiveBuyersImportedMsg(result.buyersImported));
    }
    if (result.repairsImported > 0) {
      parts.add(s.archiveRepairsImportedMsg(result.repairsImported));
    }
    if (result.skipped > 0) {
      parts.add(s.archiveSkippedMsg(result.skipped));
    }
    if (parts.isEmpty) parts.add(s.archiveNothingToImport);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(parts.join(' · ')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final year = widget.archive['year'] as int?;
    final exportedAt = widget.archive['exportedAt'] as String?;

    final totalRevenue = _sales.fold<double>(0, (sale, saleMap) {
      final items =
          (saleMap['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return sale +
          items.fold<double>(
            0,
            (iSum, i) => iSum + ((i['price'] as num?)?.toDouble() ?? 0),
          );
    });
    final paidCount = _sales
        .where((sale) => (sale['payment'] as Map?)?['status'] == 'paid')
        .length;

    final currencyFormat = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(year != null ? '${s.archive} $year' : s.archive),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ArchiveAnalyticsScreen(archive: widget.archive),
              ),
            ),
          ),
          if (_importing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _confirmImport,
              icon: const Icon(Icons.download),
              label: Text(s.archiveImportAction),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status banner
          Card(
            color: _lastResult != null
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lastResult != null ? s.archiveImported : s.archiveReadOnly,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _lastResult != null
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (exportedAt != null)
                    Text(
                      s.archiveExportedAt(
                        dateFormat.format(DateTime.parse(exportedAt)),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _lastResult != null
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  if (_lastResult != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.archiveResultBrief(
                        _lastResult!.salesImported,
                        _lastResult!.buyersImported,
                        _lastResult!.repairsImported,
                        _lastResult!.skipped,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StatRow(label: s.totalSalesLabel, value: '${_sales.length}'),
          _StatRow(label: s.paid, value: '$paidCount / ${_sales.length}'),
          _StatRow(
            label: s.archiveTotalRevenue,
            value: currencyFormat.format(totalRevenue),
          ),
          _StatRow(label: s.buyers, value: '${_buyers.length}'),
          const SizedBox(height: 24),
          Text(
            s.navSales,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (_sales.isEmpty)
            Text(s.archiveNoSales)
          else
            ..._sales.map((sale) => _ArchivedSaleTile(sale: sale)),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ArchivedSaleTile extends StatelessWidget {
  const _ArchivedSaleTile({required this.sale});
  final Map<String, dynamic> sale;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final items = (sale['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final totalPrice = items.fold<double>(
      0,
      (sum, i) => sum + ((i['price'] as num?)?.toDouble() ?? 0),
    );
    final isPaid = (sale['payment'] as Map?)?['status'] == 'paid';
    final allPhotoUrls = items.expand(
      (i) => (i['photoUrls'] as List?)?.cast<String>() ?? <String>[],
    );
    final photoUrls = allPhotoUrls.take(4).toList();

    final createdAt = sale['createdAt'];
    var dateStr = '';
    if (createdAt is String) {
      dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt));
    } else if (createdAt is Map && createdAt['_seconds'] != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (createdAt['_seconds'] as int) * 1000,
      );
      dateStr = DateFormat('dd MMM yyyy').format(dt);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(sale['buyerName'] as String? ?? s.archiveUnknown),
            subtitle: Text(
              items.isEmpty
                  ? '—'
                  : items.length == 1
                  ? (items.first['description'] as String? ?? '—')
                  : '${items.length} items',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('€${totalPrice.toStringAsFixed(2)}'),
                Text(
                  isPaid ? s.paid : s.unpaid,
                  style: TextStyle(
                    fontSize: 11,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(dateStr, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          if (photoUrls.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: photoUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photoUrls[i],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: 64,
                      height: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
