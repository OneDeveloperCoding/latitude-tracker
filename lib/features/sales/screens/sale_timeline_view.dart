import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/screens/sale_card.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({
    required this.groups,
    required this.buyerNifById,
    required this.onSaleTap,
    super.key,
    this.selectedSaleId,
  });
  final Map<String, List<Sale>> groups;
  final Map<String, String?> buyerNifById;
  final String? selectedSaleId;
  final void Function(Sale) onSaleTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final keys = groups.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final groupSales = groups[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                s.timelineLabel(key),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...groupSales.map((sale) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SaleCard(
                    sale: sale,
                    buyerNif: buyerNifById[sale.buyerId],
                    isSelected: sale.id == selectedSaleId,
                    onTap: () => onSaleTap(sale),
                  ),
                )),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}
