import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/services/auth_revoked_exception.dart';
import '../../demo/demo_mode.dart';
import '../models/sale.dart';
import '../services/photo_service.dart';
import 'photo_grid.dart';

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
  final ComponentItem component;
  final String saleId;
  final String itemId;
  final bool isReadOnly;
  final ValueChanged<ComponentItem>? onChanged;
  final ValueChanged<String>? onPhotoAdded;
  final ValueChanged<String>? onPhotoRemoved;

  const ComponentDetailSheet({
    super.key,
    required this.component,
    required this.saleId,
    required this.itemId,
    this.isReadOnly = false,
    this.onChanged,
    this.onPhotoAdded,
    this.onPhotoRemoved,
  });

  @override
  State<ComponentDetailSheet> createState() => _ComponentDetailSheetState();
}

class _ComponentDetailSheetState extends State<ComponentDetailSheet> {
  final _photoService = PhotoService();
  late ComponentItem _component;
  late final TextEditingController _notesController;
  int _uploadingCount = 0;

  @override
  void initState() {
    super.initState();
    _component = widget.component;
    _notesController =
        TextEditingController(text: widget.component.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggle() {
    final updated =
        _component.copyWith(isAvailable: !_component.isAvailable);
    setState(() => _component = updated);
    widget.onChanged?.call(updated);
  }

  void _saveNotes(String value) {
    final notes = value.trim().isEmpty ? null : value.trim();
    final updated = _component.copyWith(notes: notes);
    setState(() => _component = updated);
    widget.onChanged?.call(updated);
  }

  Future<void> _addPhoto(ImageSource source) async {
    setState(() => _uploadingCount++);
    try {
      final url = await _photoService.pickAndUploadForComponent(
        saleId: widget.saleId,
        itemId: widget.itemId,
        componentId: _component.id,
        source: source,
      );
      if (url != null) {
        widget.onPhotoAdded?.call(url);
        final updated =
            _component.copyWith(photoUrls: [..._component.photoUrls, url]);
        setState(() => _component = updated);
        widget.onChanged?.call(updated);
      }
    } catch (e) {
      if (e is AuthRevokedException) {
        FirebaseAuth.instance.signOut();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorUploadingPhotoMsg(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingCount--);
    }
  }

  Future<void> _removePhoto(int index) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.removePhotoTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.removePhoto),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final url = _component.photoUrls[index];
    widget.onPhotoRemoved?.call(url);
    final updated = _component.copyWith(
      photoUrls: [..._component.photoUrls]..removeAt(index),
    );
    setState(() => _component = updated);
    widget.onChanged?.call(updated);
  }

  void _showSourcePicker() {
    final s = context.s;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(s.takePhoto),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(s.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
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
            _EditablePhotoGrid(
              photos: photos,
              uploadingCount: _uploadingCount,
              onAddTap: _showSourcePicker,
              onRemove: _removePhoto,
            ),
        ],
      ),
    );
  }
}

class _EditablePhotoGrid extends StatelessWidget {
  final List<String> photos;
  final int uploadingCount;
  final VoidCallback onAddTap;
  final Future<void> Function(int index) onRemove;

  const _EditablePhotoGrid({
    required this.photos,
    required this.uploadingCount,
    required this.onAddTap,
    required this.onRemove,
  });

  void _viewPhoto(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewer(urls: photos, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...photos.asMap().entries.map(
              (e) => _PhotoTileCompat(
                url: e.value,
                onTap: () => _viewPhoto(context, e.key),
                onDelete: () => onRemove(e.key),
              ),
            ),
        ...List.generate(
          uploadingCount,
          (_) => const _PhotoTileCompat(isUploading: true),
        ),
        if (!DemoMode.active.value) _AddPhotoTileCompat(onTap: onAddTap),
      ],
    );
  }
}

class _ReadOnlyPhotoGrid extends StatelessWidget {
  final List<String> photos;

  const _ReadOnlyPhotoGrid({required this.photos});

  void _viewPhoto(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewer(urls: photos, initialIndex: index),
      ),
    );
  }

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
            (e) => _PhotoTileCompat(
              url: e.value,
              onTap: () => _viewPhoto(context, e.key),
            ),
          ).toList(),
    );
  }
}

// Minimal local photo tile — mirrors _PhotoTile in photo_grid.dart but
// without the dependency on the parent widget's state.
class _PhotoTileCompat extends StatelessWidget {
  static const double _size = 96;

  final String? url;
  final bool isUploading;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _PhotoTileCompat({
    this.url,
    this.isUploading = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cacheSize = (_size * MediaQuery.devicePixelRatioOf(context)).round();
    return SizedBox(
      width: _size,
      height: _size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isUploading)
              Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              )
            else
              GestureDetector(
                onTap: onTap,
                child: Image.network(
                  url!,
                  fit: BoxFit.cover,
                  cacheWidth: cacheSize,
                  cacheHeight: cacheSize,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                              child: CircularProgressIndicator()),
                        ),
                  errorBuilder: (context, err, stack) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            if (onDelete != null && !isUploading)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.close,
                        size: 20, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTileCompat extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoTileCompat({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              context.s.addPhoto,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon button showing the component photo count. Tapping opens the sheet.
/// Shows a camera icon when count is 0 (to signal photos are available),
/// and a filled badge with the count when photos exist.
class ComponentPhotoBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const ComponentPhotoBadge({
    super.key,
    required this.count,
    required this.onTap,
  });

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
            : Icon(Icons.add_a_photo_outlined, size: 16, color: color.withAlpha(120)),
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
  return showModalBottomSheet(
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
