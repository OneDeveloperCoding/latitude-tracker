import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import 'package:latitude_tracker/core/id_gen.dart';

import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/photo_service.dart';
import 'package:latitude_tracker/features/sales/widgets/category_picker.dart';
import 'package:latitude_tracker/features/sales/widgets/component_detail_sheet.dart';
import 'package:latitude_tracker/features/sales/widgets/photo_grid.dart';

/// Full-screen editor for adding or editing a single SaleItem.
/// Pushed from NewSaleScreen and returns the completed [SaleItem] on save,
/// or null when the user cancels.
///
/// Photo lifecycle: photos uploaded in this session are cleaned up if the
/// user cancels. The caller is responsible for executing `pendingDeletions`
/// (pre-existing photos the user removed) when the outer form is saved.
class SaleItemScreen extends StatefulWidget {

  const SaleItemScreen({required this.saleId, super.key, this.item});
  final String saleId;
  final SaleItem? item;

  @override
  State<SaleItemScreen> createState() => _SaleItemScreenState();
}

class _SaleItemScreenState extends State<SaleItemScreen> {
  final _photoService = PhotoService();
  final _newComponentController = TextEditingController();

  late final String _itemId;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late String? _category;
  late AssemblyStatus _assemblyStatus;
  late List<ComponentItem> _components;
  late List<String> _photoUrls;
  late final List<String> _originalPhotoUrls;
  late final Set<String> _originalComponentPhotoUrls;
  final List<String> _uploadedInSession = [];
  final List<String> _pendingDeletions = [];

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _itemId = item?.id ?? newId();
    _descController = TextEditingController(text: item?.description ?? '');
    _priceController = TextEditingController(
        text: item != null ? item.price.toStringAsFixed(2) : '');
    _category = item?.category;
    _assemblyStatus = item?.assemblyStatus ?? AssemblyStatus.notStarted;
    _components = List.from(item?.components ?? []);
    _photoUrls = List.from(item?.photoUrls ?? []);
    _originalPhotoUrls = List.from(item?.photoUrls ?? []);
    _originalComponentPhotoUrls = {
      for (final c in item?.components ?? <ComponentItem>[]) ...c.photoUrls,
    };
  }

  @override
  void dispose() {
    _descController.dispose();
    _priceController.dispose();
    _newComponentController.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    // Delete photos uploaded in this session that are no longer in _photoUrls
    // (the user added them and then removed them), plus any still in _photoUrls
    // that were uploaded this session (user added them but is now cancelling).
    final toDelete = _uploadedInSession.toSet();
    for (final url in toDelete) {
      await _photoService.deletePhoto(url);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _save() {
    final s = context.s;
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.descriptionRequired)));
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.categoryRequired)));
      return;
    }
    final rawPrice = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(rawPrice);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.invalidPrice)));
      return;
    }

    final result = SaleItemResult(
      item: SaleItem(
        id: _itemId,
        description: desc,
        category: _category!,
        price: price,
        assemblyStatus: _assemblyStatus,
        components: _components,
        photoUrls: _photoUrls,
      ),
      pendingDeletions: List.from(_pendingDeletions),
    );
    Navigator.of(context).pop(result);
  }

  void _addComponent() {
    final name = _newComponentController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _components.add(ComponentItem(
        id: newId(),
        name: name,
        isAvailable: false,
      ));
      _newComponentController.clear();
    });
  }

  void _toggleComponent(int index) {
    setState(() {
      final updated = List<ComponentItem>.from(_components);
      updated[index] =
          updated[index].copyWith(isAvailable: !updated[index].isAvailable);
      _components = updated;
    });
  }

  void _adjustQuantity(int index, int delta) {
    setState(() {
      final updated = List<ComponentItem>.from(_components);
      updated[index] = updated[index].adjustedQuantity(delta);
      _components = updated;
    });
  }

  Future<void> _removeComponent(int index) async {
    final component = _components[index];
    for (final url in component.photoUrls) {
      if (_originalComponentPhotoUrls.contains(url)) {
        _pendingDeletions.add(url);
      } else {
        _uploadedInSession.remove(url);
        await _photoService.deletePhoto(url);
      }
    }
    if (!mounted) return;
    setState(() => _components = List<ComponentItem>.from(_components)..removeAt(index));
  }

  Future<void> _openComponentSheet(int index) async {
    final component = _components[index];
    await showComponentDetailSheet(
      context,
      component: component,
      saleId: widget.saleId,
      itemId: _itemId,
      onChanged: (updated) {
        setState(() {
          final list = List<ComponentItem>.from(_components);
          list[index] = updated;
          _components = list;
        });
      },
      onPhotoAdded: _uploadedInSession.add,
      onPhotoRemoved: (url) {
        if (_originalComponentPhotoUrls.contains(url)) {
          _pendingDeletions.add(url);
        } else {
          _uploadedInSession.remove(url);
          unawaited(_photoService.deletePhoto(url));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? s.editItem : s.addItem),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancel,
          ),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text(s.save),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
          children: [
            // ── Item details ───────────────────────────────────────────────
            _FormCard(
              title: s.sectionItem,
              child: Column(
                children: [
                  TextFormField(
                    controller: _descController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: s.descriptionLabel,
                      hintText: s.descriptionHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showCategoryPicker(context,
                          current: _category);
                      if (picked != null) setState(() => _category = picked);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: s.categoryLabel,
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                      child: Text(
                        _category ?? s.categoryPickerHint,
                        style: _category == null
                            ? TextStyle(color: Theme.of(context).hintColor)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: s.priceLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AssemblyStatus>(
                    initialValue: _assemblyStatus,
                    decoration: InputDecoration(
                      labelText: s.assemblyStatusLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: AssemblyStatus.values
                        .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(s.assemblyLabel(status))))
                        .toList(),
                    onChanged: (v) => setState(() => _assemblyStatus = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Photos ─────────────────────────────────────────────────────
            _FormCard(
              title: s.sectionPhotos,
              child: PhotoGrid(
                saleId: widget.saleId,
                itemId: _itemId,
                photoUrls: _photoUrls,
                onChanged: (urls) => setState(() => _photoUrls = urls),
                onPhotoAdded: _uploadedInSession.add,
                onPhotoRemoved: (url) {
                  if (_originalPhotoUrls.contains(url)) {
                    _pendingDeletions.add(url);
                  } else {
                    _photoService.deletePhoto(url);
                    _uploadedInSession.remove(url);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            // ── Components ─────────────────────────────────────────────────
            _FormCard(
              title: s.sectionComponents,
              child: Column(
                children: [
                  ..._components.asMap().entries.map(
                        (entry) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Expanded(child: Text(entry.value.name)),
                              ComponentQuantityStepper(
                                quantity: entry.value.quantity,
                                onChanged: (q) => _adjustQuantity(entry.key, q - entry.value.quantity),
                              ),
                            ],
                          ),
                          subtitle: Text(entry.value.isAvailable
                              ? s.haveIt
                              : s.needToBuy),
                          value: entry.value.isAvailable,
                          onChanged: (_) => _toggleComponent(entry.key),
                          secondary: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ComponentPhotoBadge(
                                count: entry.value.photoUrls.length,
                                onTap: () => _openComponentSheet(entry.key),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () =>
                                    _removeComponent(entry.key),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newComponentController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: s.addComponentHint,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addComponent(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addComponent,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class SaleItemResult {

  const SaleItemResult({required this.item, required this.pendingDeletions});
  final SaleItem item;
  final List<String> pendingDeletions;
}

class _FormCard extends StatelessWidget {

  const _FormCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Helper to push [SaleItemScreen] and unwrap the typed result.
/// Returns the result or null if the user cancelled.
Future<SaleItemResult?> pushSaleItemScreen(
  BuildContext context, {
  required String saleId,
  SaleItem? item,
}) {
  return Navigator.push<SaleItemResult>(
    context,
    MaterialPageRoute<SaleItemResult>(
      builder: (_) => SaleItemScreen(saleId: saleId, item: item),
    ),
  );
}
