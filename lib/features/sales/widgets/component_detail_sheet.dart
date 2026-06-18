import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/screens/shopping_list_screen.dart' show ShoppingListScreen;
import 'package:latitude_tracker/features/sales/services/photo_service.dart';
import 'package:latitude_tracker/features/sales/widgets/photo_grid.dart';

/// Bottom sheet for viewing or editing a single [ComponentItem].
///
/// In edit mode ([isReadOnly] = false): the toggle, notes, and photo grid are
/// all interactive. [onChanged] is called with the updated component on every
/// change; the caller is responsible for persisting and for photo lifecycle
/// (tracking session uploads and pending deletions via [onPhotoAdded] /
/// [onPhotoRemoved]).
///
/// In read-only mode ([isReadOnly] = true): everything is displayed but not
/// editable. Used from [ShoppingListScreen] where photos are needed for visual
/// reference but management happens elsewhere.
class ComponentDetailSheet extends StatefulWidget {

  const ComponentDetailSheet({
    required this.component, required this.saleId, required this.itemId, super.key,
    this.isReadOnly = false,
    this.onChanged,
    this.onPhotoAdded,
    this.onPhotoRemoved,
  });
  final ComponentItem component;
  final String saleId;
  final String itemId;
  final bool isReadOnly;
  final ValueChanged<ComponentItem>? onChanged;
  final ValueChanged<String>? onPhotoAdded;
  final ValueChanged<String>? onPhotoRemoved;

  @override
  State<ComponentDetailSheet> createState() => _ComponentDetailSheetState();
}

class _ComponentDetailSheetState extends State<ComponentDetailSheet> {
  final _photoService = PhotoService();
  late ComponentItem _component;
  late final TextEditingController _notesController;
  Timer? _notesDebounce;

  @override
  void initState() {
    super.initState();
    _component = widget.component;
    _notesController =
        TextEditingController(text: widget.component.notes ?? '');
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _toggle() {
    final updated =
        _component.copyWith(isAvailable: !_component.isAvailable);
    setState(() => _component = updated);
    widget.onChanged?.call(updated);
  }

  // Debounced to avoid a Firestore write on every keystroke.
  void _saveNotes(String value) {
    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 600), () {
      final trimmed = value.trim();
      final notes = trimmed.isEmpty ? null : trimmed;
      final updated = _component.copyWith(notes: notes);
      setState(() => _component = updated);
      widget.onChanged?.call(updated);
    });
  }

  void _updatePhotos(List<String> urls) {
    final updated = _component.copyWith(photoUrls: urls);
    setState(() => _component = updated);
    widget.onChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final photos = _component.photoUrls;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Component name ───────────────────────────────────────────────
          Text(
            _component.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          // ── Have / need-to-buy toggle ────────────────────────────────────
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_component.isAvailable ? s.haveIt : s.needToBuy),
            value: _component.isAvailable,
            onChanged: widget.isReadOnly ? null : (_) => _toggle(),
          ),
          const SizedBox(height: 8),
          // ── Notes ────────────────────────────────────────────────────────
          if (!widget.isReadOnly) ...[
            TextField(
              controller: _notesController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: s.componentNotesLabel,
                hintText: s.componentNotesHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: _saveNotes,
            ),
            const SizedBox(height: 16),
          ] else if (_component.notes != null) ...[
            Text(
              _component.notes!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
          ],
          // ── Photos ───────────────────────────────────────────────────────
          Text(
            s.sectionPhotos,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          if (widget.isReadOnly)
            _ReadOnlyPhotoGrid(photos: photos)
          else
            PhotoGrid(
              saleId: widget.saleId,
              itemId: widget.itemId,
              photoUrls: photos,
              uploadCallback: (source) =>
                  _photoService.pickAndUploadForComponent(
                saleId: widget.saleId,
                itemId: widget.itemId,
                componentId: _component.id,
                source: source,
              ),
              onChanged: _updatePhotos,
              onPhotoAdded: widget.onPhotoAdded,
              onPhotoRemoved: widget.onPhotoRemoved,
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyPhotoGrid extends StatelessWidget {

  const _ReadOnlyPhotoGrid({required this.photos});
  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Text(
        context.s.noPhotos,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: photos.asMap().entries.map(
            (e) => PhotoThumbnail(
              url: e.value,
              size: 96,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PhotoViewer(urls: photos, initialIndex: e.key),
                ),
              ),
            ),
          ).toList(),
    );
  }
}

/// Icon button showing the component photo count. Tapping opens the sheet.
/// Shows a camera icon when count is 0 (to signal photos are available),
/// and a filled badge with the count when photos exist.
class ComponentPhotoBadge extends StatelessWidget {

  const ComponentPhotoBadge({
    required this.count, required this.onTap, super.key,
  });
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: count > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, size: 16, color: color),
                  const SizedBox(width: 2),
                  Text(
                    '$count',
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Icon(Icons.add_a_photo_outlined,
                size: 16, color: color.withAlpha(120)),
      ),
    );
  }
}

/// Compact inline stepper (− count +) for a [ComponentItem] quantity.
/// Enforces a minimum of 1. Only the buttons trigger [onChanged].
class ComponentQuantityStepper extends StatelessWidget {

  const ComponentQuantityStepper({
    required this.quantity, required this.onChanged, super.key,
  });
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          color: color,
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '$quantity',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          color: color,
          onPressed: quantity < kMaxComponentQuantity
              ? () => onChanged(quantity + 1)
              : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {

  const _StepButton(
      {required this.icon, required this.color, required this.onPressed});
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon,
            size: 16, color: onPressed != null ? color : color.withAlpha(60)),
      ),
    );
  }
}

/// Opens [ComponentDetailSheet] as a modal bottom sheet.
Future<void> showComponentDetailSheet(
  BuildContext context, {
  required ComponentItem component,
  required String saleId,
  required String itemId,
  bool isReadOnly = false,
  ValueChanged<ComponentItem>? onChanged,
  ValueChanged<String>? onPhotoAdded,
  ValueChanged<String>? onPhotoRemoved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ComponentDetailSheet(
      component: component,
      saleId: saleId,
      itemId: itemId,
      isReadOnly: isReadOnly,
      onChanged: onChanged,
      onPhotoAdded: onPhotoAdded,
      onPhotoRemoved: onPhotoRemoved,
    ),
  );
}
