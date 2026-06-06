import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/services/auth_revoked_exception.dart';
import '../../demo/demo_mode.dart';
import '../../sales/widgets/photo_grid.dart' show PhotoViewer;
import '../services/repair_photo_service.dart';

class RepairPhotoGrid extends StatefulWidget {
  final String repairId;
  final List<String> photoUrls;

  /// Called with the URL when a new photo finishes uploading.
  final ValueChanged<String> onUploaded;

  /// Called with the URL when the user confirms removing a photo.
  final ValueChanged<String> onRemoved;

  const RepairPhotoGrid({
    super.key,
    required this.repairId,
    required this.photoUrls,
    required this.onUploaded,
    required this.onRemoved,
  });

  @override
  State<RepairPhotoGrid> createState() => _RepairPhotoGridState();
}

class _RepairPhotoGridState extends State<RepairPhotoGrid> {
  final _service = RepairPhotoService();
  int _uploadingCount = 0;

  Future<void> _addPhoto(ImageSource source) async {
    setState(() => _uploadingCount++);
    try {
      final url = await _service.pickAndUpload(
        repairId: widget.repairId,
        source: source,
      );
      if (url != null) widget.onUploaded(url);
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

  Future<void> _confirmRemove(int index) async {
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
    widget.onRemoved(widget.photoUrls[index]);
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
    final photos = widget.photoUrls;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...photos.asMap().entries.map(
                  (entry) => _DeletablePhotoTile(
                    url: entry.value,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewer(
                          urls: photos,
                          initialIndex: entry.key,
                        ),
                      ),
                    ),
                    onDelete: () => _confirmRemove(entry.key),
                  ),
                ),
            ...List.generate(
              _uploadingCount,
              (_) => const _UploadingTile(),
            ),
            if (!DemoMode.active.value)
              _AddPhotoTile(onTap: _showSourcePicker),
          ],
        ),
      ],
    );
  }
}

class _DeletablePhotoTile extends StatelessWidget {
  static const double _displaySize = 96;

  final String url;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeletablePhotoTile({
    required this.url,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cacheSize =
        (_displaySize * MediaQuery.devicePixelRatioOf(context)).round();
    return SizedBox(
      width: _displaySize,
      height: _displaySize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: onTap,
              child: url.startsWith('demo://')
                  ? _DemoPlaceholder(url: url)
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      cacheWidth: cacheSize,
                      cacheHeight: cacheSize,
                      errorBuilder: (_, e, s) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
            ),
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
                    borderRadius:
                        BorderRadius.only(bottomLeft: Radius.circular(8)),
                  ),
                  child:
                      const Icon(Icons.close, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoPlaceholder extends StatelessWidget {
  final String url;
  const _DemoPlaceholder({required this.url});

  @override
  Widget build(BuildContext context) {
    final idx = ((RegExp(r'\d+$').firstMatch(url) != null
                ? int.parse(RegExp(r'\d+$').firstMatch(url)!.group(0)!)
                : 1) -
            1) %
        4;
    final colors = [
      [const Color(0xFFE1BEE7), const Color(0xFFF8BBD9)],
      [const Color(0xFFB2EBF2), const Color(0xFFB3E5FC)],
      [const Color(0xFFFFE0B2), const Color(0xFFFFF9C4)],
      [const Color(0xFFC8E6C9), const Color(0xFFB2DFDB)],
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors[idx],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
          child: Icon(Icons.build_outlined, size: 32, color: Colors.white70)),
    );
  }
}

class _UploadingTile extends StatelessWidget {
  const _UploadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoTile({required this.onTap});

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
