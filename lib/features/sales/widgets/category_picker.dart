import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/sales_store.dart';
import '../../settings/repositories/catalogue_repository.dart';
import '../models/sale.dart';

/// Opens a bottom sheet that lets the user pick an existing category or type a
/// new one. Fetches the hidden-category list once before showing the sheet so
/// hidden categories are excluded from the picker.
Future<String?> showCategoryPicker(
  BuildContext context, {
  String? current,
}) async {
  final hidden = await CatalogueRepository().fetchHiddenCategories();
  if (!context.mounted) return null;
  final allCategories = _buildSortedCategories(hidden.toSet());
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CategoryPickerSheet(
      allCategories: allCategories,
      current: current,
    ),
  );
}

/// Returns deduplicated, visible categories sorted by usage frequency descending.
/// Seeds from [kDefaultCategories] so the list is never empty on a fresh install.
List<String> _buildSortedCategories(Set<String> hidden) {
  final counts = <String, int>{};
  for (final sale in SalesStore.current ?? []) {
    for (final item in sale.items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
  }
  for (final cat in kDefaultCategories) {
    counts.putIfAbsent(cat, () => 0);
  }
  return counts.keys
      .where((cat) => !hidden.contains(cat))
      .toList()
    ..sort((a, b) {
      final cmp = counts[b]!.compareTo(counts[a]!);
      return cmp != 0 ? cmp : a.compareTo(b);
    });
}

class _CategoryPickerSheet extends StatefulWidget {
  final List<String> allCategories;
  final String? current;

  const _CategoryPickerSheet({
    required this.allCategories,
    this.current,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;

    final filtered = widget.allCategories
        .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final showAddNew = _query.isNotEmpty &&
        !widget.allCategories
            .any((c) => c.toLowerCase() == _query.toLowerCase().trim());

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (_, scrollController) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    hintText: s.searchOrAddCategory,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (showAddNew)
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: Text(s.addCategoryLabel(_query.trim())),
                        onTap: () =>
                            Navigator.pop(context, _query.trim()),
                      ),
                    ...filtered.map(
                      (cat) => ListTile(
                        title: Text(cat),
                        trailing: cat == widget.current
                            ? Icon(Icons.check,
                                color: colorScheme.primary)
                            : null,
                        onTap: () => Navigator.pop(context, cat),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
