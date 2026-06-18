import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/services/auth_revoked_exception.dart';
import 'package:latitude_tracker/features/demo/demo_mode.dart';
import 'package:latitude_tracker/features/sales/services/photo_service.dart';

class PhotoGrid extends StatefulWidget {
  const PhotoGrid({
    required this.saleId,
    required this.itemId,
    required this.photoUrls,
    required this.onChanged,
    super.key,
    this.onPhotoAdded,
    this.onPhotoRemoved,
    this.uploadCallback,
  });
  final String saleId;
  final String itemId;
  final List<String> photoUrls;
  final ValueChanged<List<String>> onChanged;

  /// Called with the URL when a new photo finishes uploading.
  final ValueChanged<String>? onPhotoAdded;

  /// Called with the URL when the user confirms removing a photo.
  /// Parent is responsible for deleting from storage when appropriate.
  final ValueChanged<String>? onPhotoRemoved;

  /// When provided, replaces the default [PhotoService.pickAndUpload] call.
  /// Lets callers supply their own upload path (e.g. component photos).
  final Future<String?> Function(ImageSource)? uploadCallback;

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  final _service = PhotoService();
  int _uploadingCount = 0;

  Future<void> _addPhoto(ImageSource source) async {
    setState(() => _uploadingCount++);
    try {
      final url = widget.uploadCallback != null
          ? await widget.uploadCallback!(source)
          : await _service.pickAndUpload(
              saleId: widget.saleId,
              itemId: widget.itemId,
              source: source,
            );
      if (url != null) {
        widget.onPhotoAdded?.call(url);
        widget.onChanged([...widget.photoUrls, url]);
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

    final url = widget.photoUrls[index];
    widget.onPhotoRemoved?.call(url);
    final updated = [...widget.photoUrls]..removeAt(index);
    widget.onChanged(updated);
  }

  void _showSourcePicker() {
    final s = context.s;
    showModalBottomSheet<void>(
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

  void _viewPhoto(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewer(
          urls: widget.photoUrls,
          initialIndex: index,
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
              (entry) => _PhotoTile(
                url: entry.value,
                isUploading: false,
                onTap: () => _viewPhoto(context, entry.key),
                onDelete: () => _removePhoto(entry.key),
              ),
            ),
            ...List.generate(
              _uploadingCount,
              (_) => const _PhotoTile(isUploading: true),
            ),
            if (!DemoMode.active.value) _AddPhotoTile(onTap: _showSourcePicker),
          ],
        ),
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${photos.length} photo${photos.length == 1 ? '' : 's'} — tap to'
              ' view',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.isUploading,
    this.url,
    this.onTap,
    this.onDelete,
  });
  static const double _displaySize = 96;

  final String? url;
  final bool isUploading;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cacheSize = (_displaySize * MediaQuery.devicePixelRatioOf(context))
        .round();
    return SizedBox(
      width: _displaySize,
      height: _displaySize,
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
            else if (url!.startsWith('demo://'))
              GestureDetector(
                onTap: onTap,
                child: _DemoPhotoPlaceholder(url: url!),
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
                            child: CircularProgressIndicator(),
                          ),
                        ),
                  errorBuilder: (context, error, stack) => Container(
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
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DemoPhotoPlaceholder extends StatelessWidget {
  const _DemoPhotoPlaceholder({required this.url, this.large = false});
  final String url;
  final bool large;

  static const _palettes = [
    [Color(0xFFE1BEE7), Color(0xFFF8BBD9)], // purple/pink
    [Color(0xFFB2EBF2), Color(0xFFB3E5FC)], // teal/blue
    [Color(0xFFFFE0B2), Color(0xFFFFF9C4)], // amber/yellow
    [Color(0xFFC8E6C9), Color(0xFFB2DFDB)], // green/teal
  ];

  static const List<IconData> _icons = [
    Icons.diamond_outlined,
    Icons.auto_awesome,
    Icons.shopping_bag_outlined,
    Icons.favorite_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'\d+$').firstMatch(url);
    final idx =
        ((match != null ? int.parse(match.group(0)!) : 1) - 1) %
        _palettes.length;
    final size = large ? 200.0 : 96.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _palettes[idx],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: large ? null : BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(_icons[idx], size: large ? 64 : 32, color: Colors.white70),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});
  final VoidCallback onTap;

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
            Icon(
              Icons.add_a_photo,
              color: Theme.of(context).colorScheme.primary,
            ),
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

class PhotoThumbnail extends StatelessWidget {
  const PhotoThumbnail({
    required this.url,
    super.key,
    this.size = 48,
    this.onTap,
  });
  final String url;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final image = url.startsWith('demo://')
        ? _DemoPhotoPlaceholder(url: url)
        : Image.network(
            url,
            fit: BoxFit.cover,
            cacheWidth: cacheSize,
            cacheHeight: cacheSize,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : Container(color: Colors.grey[200]),
            errorBuilder: (_, err, stack) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, size: 16),
            ),
          );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: image,
        ),
      ),
    );
  }
}

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    required this.urls,
    required this.initialIndex,
    super.key,
  });
  final List<String> urls;
  final int initialIndex;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late int _current;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, index) {
          final url = widget.urls[index];
          if (url.startsWith('demo://')) {
            return Center(child: _DemoPhotoPlaceholder(url: url, large: true));
          }
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                errorBuilder: (_, err, stack) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
