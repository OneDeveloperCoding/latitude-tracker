import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/repairs_store.dart';
import '../../../core/store/sales_store.dart';
import '../../demo/demo_mode.dart';
import '../../sales/models/sale.dart';
import '../repositories/catalogue_repository.dart';
import '../services/category_service.dart';

class CategoryMaintenanceScreen extends StatefulWidget {
  const CategoryMaintenanceScreen({super.key});

  @override
  State<CategoryMaintenanceScreen> createState() =>
      _CategoryMaintenanceScreenState();
}

class _CategoryMaintenanceScreenState
    extends State<CategoryMaintenanceScreen> {
  final _service = CategoryService();
  final _repo = CatalogueRepository();

  List<String> _hidden = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHidden();
  }

  Future<void> _loadHidden() async {
    final hidden = await _repo.fetchHiddenCategories();
    if (mounted) setState(() { _hidden = hidden; _loading = false; });
  }

  List<_CategoryEntry> _buildEntries() {
    final counts = <String, int>{};

    for (final sale in SalesStore.current ?? []) {
      for (final item in sale.items) {
        counts[item.category] = (counts[item.category] ?? 0) + 1;
      }
    }
    for (final repair in RepairsStore.current ?? []) {
      counts[repair.itemCategory] =
          (counts[repair.itemCategory] ?? 0) + 1;
    }

    final known = {
      ...kDefaultCategories,
      ..._hidden,
      ...counts.keys,
    };

    return known
        .map((name) => _CategoryEntry(
              name: name,
              useCount: counts[name] ?? 0,
              isHidden: _hidden.contains(name),
            ))
        .toList()
      ..sort((a, b) {
        final cmp = b.useCount.compareTo(a.useCount);
        return cmp != 0 ? cmp : a.name.compareTo(b.name);
      });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final isDemo = DemoMode.active.value;
    final entries = _buildEntries();

    return Scaffold(
      appBar: AppBar(title: Text(s.categoriesTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (isDemo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      s.demoBanner,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ...entries.map((e) => _CategoryTile(
                      entry: e,
                      onRename: () => isDemo ? _showDemoBlocked() : _showRenameDialog(e),
                      onToggleHide: () => isDemo ? _showDemoBlocked() : _toggleHide(e),
                      onDelete: () => isDemo ? _showDemoBlocked() : _confirmDelete(e),
                    )),
              ],
            ),
    );
  }

  void _showDemoBlocked() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.demoBanner)),
    );
  }

  Future<void> _showRenameDialog(_CategoryEntry entry) async {
    final s = context.s;
    final controller = TextEditingController(text: entry.name);
    String? error;
    final allNames = _buildEntries().map((e) => e.name).toSet();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(s.renameCategoryTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: s.renameCategoryHint,
              errorText: error,
            ),
            onChanged: (_) {
              if (error != null) setDialogState(() => error = null);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isEmpty) {
                  setDialogState(() => error = s.renameCategoryEmpty);
                  return;
                }
                if (newName != entry.name &&
                    allNames.contains(newName)) {
                  setDialogState(() => error = s.renameCategoryDuplicate);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(s.rename),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final newName = controller.text.trim();
    if (newName == entry.name) return;

    try {
      await _runWithProgress(s.renamingCategory, () async {
        await _service.renameCategory(entry.name, newName, _hidden);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.errorMsg(e))),
        );
      }
      return;
    }
    if (mounted) await _loadHidden();
  }

  Future<void> _toggleHide(_CategoryEntry entry) async {
    try {
      if (entry.isHidden) {
        await _service.unhideCategory(entry.name, _hidden);
      } else {
        await _service.hideCategory(entry.name, _hidden);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorMsg(e))),
        );
      }
      return;
    }
    if (mounted) await _loadHidden();
  }

  Future<void> _confirmDelete(_CategoryEntry entry) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.categoryDeleteTitle(entry.name)),
        content: Text(s.categoryDeleteBody(entry.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteCategory(entry.name, _hidden);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.errorMsg(e))),
        );
      }
      return;
    }
    if (mounted) await _loadHidden();
  }

  Future<void> _runWithProgress(
    String message,
    Future<void> Function() action,
  ) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
    try {
      await action();
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }
}

class _CategoryEntry {
  final String name;
  final int useCount;
  final bool isHidden;

  const _CategoryEntry({
    required this.name,
    required this.useCount,
    required this.isHidden,
  });
}

enum _CategoryAction { rename, toggleHide, delete }

class _CategoryTile extends StatelessWidget {
  final _CategoryEntry entry;
  final VoidCallback onRename;
  final VoidCallback onToggleHide;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.entry,
    required this.onRename,
    required this.onToggleHide,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;
    final canDelete = entry.useCount == 0;

    return ListTile(
      title: Text(
        entry.name,
        style: entry.isHidden
            ? TextStyle(color: colorScheme.onSurface.withAlpha(102))
            : null,
      ),
      subtitle: Text(
        entry.isHidden
            ? '${s.nUses(entry.useCount)} · ${s.hiddenLabel}'
            : s.nUses(entry.useCount),
        style: entry.isHidden
            ? TextStyle(color: colorScheme.onSurface.withAlpha(102))
            : null,
      ),
      trailing: PopupMenuButton<_CategoryAction>(
              onSelected: (action) {
                switch (action) {
                  case _CategoryAction.rename:
                    onRename();
                  case _CategoryAction.toggleHide:
                    onToggleHide();
                  case _CategoryAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _CategoryAction.rename,
                  child: Text(s.rename),
                ),
                PopupMenuItem(
                  value: _CategoryAction.toggleHide,
                  child: Text(entry.isHidden ? s.unhide : s.hide),
                ),
                PopupMenuItem(
                  enabled: canDelete,
                  value: _CategoryAction.delete,
                  child: Text(
                    s.delete,
                    style: TextStyle(
                      color: canDelete
                          ? Colors.red
                          : colorScheme.onSurface.withAlpha(97),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
