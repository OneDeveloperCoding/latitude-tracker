import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/sales_store.dart';
import '../../../core/store/store_state.dart';
import '../models/sale.dart';
import '../services/sale_urgency.dart';
import '../services/shopping_list_aggregator.dart';
import '../widgets/component_detail_sheet.dart';
import 'sale_detail_screen.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.shoppingList)),
      body: ValueListenableBuilder<StoreState<List<Sale>>>(
        valueListenable: SalesStore.state,
        builder: (context, storeState, _) {
          if (storeState is StoreError<List<Sale>>) {
            return Center(child: Text(s.errorLoadingSales));
          }
          if (storeState is! StoreLoaded<List<Sale>>) {
            return const Center(child: CircularProgressIndicator());
          }

          final aggregated = aggregateShoppingList(storeState.data);

          if (aggregated.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(s.nothingLeftToBuy),
                ],
              ),
            );
          }

          final totalSources =
              aggregated.fold(0, (sum, a) => sum + a.sources.length);
          final urgentCount = aggregated
              .where((a) => a.worstUrgency != UrgencyLevel.none)
              .length;

          return ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            children: [
              _ShoppingListHeader(
                totalMaterials: aggregated.length,
                totalSources: totalSources,
                urgentCount: urgentCount,
              ),
              const SizedBox(height: 16),
              ...aggregated
                  .map((a) => _AggregatedComponentTile(aggregated: a)),
            ],
          );
        },
      ),
    );
  }
}

class _ShoppingListHeader extends StatelessWidget {
  final int totalMaterials;
  final int totalSources;
  final int urgentCount;

  const _ShoppingListHeader({
    required this.totalMaterials,
    required this.totalSources,
    required this.urgentCount,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Row(
      children: [
        Text(
          s.materialsAcrossItems(totalMaterials, totalSources),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (urgentCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: Theme.of(context).colorScheme.error.withAlpha(100)),
            ),
            child: Text(
              s.nUrgent(urgentCount),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AggregatedComponentTile extends StatefulWidget {
  final AggregatedComponent aggregated;

  const _AggregatedComponentTile({required this.aggregated});

  @override
  State<_AggregatedComponentTile> createState() =>
      _AggregatedComponentTileState();
}

class _AggregatedComponentTileState extends State<_AggregatedComponentTile> {
  bool _expanded = false;

  Color? _accentColor(BuildContext context) =>
      switch (widget.aggregated.worstUrgency) {
        UrgencyLevel.overdue => Theme.of(context).colorScheme.error,
        UrgencyLevel.thisWeek => Colors.amber[700],
        UrgencyLevel.none => null,
      };

  @override
  Widget build(BuildContext context) {
    final a = widget.aggregated;
    final accent = _accentColor(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: accent != null
            ? BoxDecoration(
                border: Border(left: BorderSide(color: accent, width: 4)))
            : null,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.totalQuantity > 1
                            ? '${a.name} × ${a.totalQuantity}'
                            : a.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Column(
                      children: [
                        const Divider(height: 1),
                        ...a.sources.map((src) => _SourceRow(source: src)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final ComponentSource source;

  const _SourceRow({required this.source});

  @override
  Widget build(BuildContext context) {
    final c = source.component;
    final item = source.item;
    final sale = source.sale;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SaleDetailScreen(saleId: sale.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${sale.buyerName} · ${item.description}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (c.quantity > 1) ...[
                  const SizedBox(width: 8),
                  Text(
                    '× ${c.quantity}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                if (c.photoUrls.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  ComponentPhotoBadge(
                    count: c.photoUrls.length,
                    onTap: () => showComponentDetailSheet(
                      context,
                      component: c,
                      saleId: sale.id,
                      itemId: item.id,
                      isReadOnly: true,
                    ),
                  ),
                ],
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            if (c.notes != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  c.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withAlpha(180),
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

