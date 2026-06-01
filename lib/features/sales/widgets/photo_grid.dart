import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/photo_service.dart';

class PhotoGrid extends StatefulWidget {
  final String saleId;
  final List<String> photoUrls;
  final ValueChanged<List<String>> onChanged;

  /// Called with the URL when a new photo finishes uploading.
  final ValueChanged<String>? onPhotoAdded;

  /// Called with the URL when the user confirms removing a photo.
  /// Parent is responsible for deleting from storage when appropriate.
  final ValueChanged<String>? onPhotoRemoved;

  const PhotoGrid({
    super.key,
    required this.saleId,
    required this.photoUrls,
    required this.onChanged,
    this.onPhotoAdded,
    this.onPhotoRemoved,
  });

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  final _service = PhotoService();
  int _uploadingCount = 0;

  Future<void> _addPhoto(ImageSource source) async {
    setState(() => _uploadingCount++);
    try {
      final url = await _service.pickAndUpload(
        saleId: widget.saleId,
        source: source,
      );
      if (url != null) {
        widget.onPhotoAdded?.call(url);
        widget.onChanged([...widget.photoUrls, url]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingCount--);
    }
  }

  Future<void> _removePhoto(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
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
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
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
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(
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
            _AddPhotoTile(onTap: _showSourcePicker),
          ],
        ),
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${photos.length} photo${photos.length == 1 ? '' : 's'} — tap to view',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String? url;
  final bool isUploading;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _PhotoTile({
    this.url,
    required this.isUploading,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
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
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                              child: CircularProgressIndicator()),
                        ),
                  errorBuilder: (_, __, ___) => Container(
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
              'Add photo',
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

class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _PhotoViewer({required this.urls, required this.initialIndex});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
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
        itemBuilder: (_, index) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.urls[index],
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
