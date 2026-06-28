import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;

const kBackupFolderName = 'Latitude Tracker Backup';
const kDataFolderName = 'data';
const kPhotosFolderName = 'photos';
const kSalesFolderName = 'sales';
const kComponentsFolderName = 'components';
const kRepairsFolderName = 'repairs';
const kIsUploadedKey = 'isUploaded';
const kIsUploadedValue = 'true';

// ---------------------------------------------------------------------------
// Photo entry types — carry enough context to build the Drive folder path and
// reconstruct the Firebase Storage destination path on restore.
// ---------------------------------------------------------------------------

sealed class PhotoEntry {
  const PhotoEntry(this.url);
  final String url;
}

class SaleItemPhoto extends PhotoEntry {
  const SaleItemPhoto({
    required this.saleId,
    required this.itemId,
    required String url,
  }) : super(url);
  final String saleId;
  final String itemId;
}

class ComponentPhoto extends PhotoEntry {
  const ComponentPhoto({
    required this.saleId,
    required this.itemId,
    required this.componentId,
    required String url,
  }) : super(url);
  final String saleId;
  final String itemId;
  final String componentId;
}

class RepairPhoto extends PhotoEntry {
  const RepairPhoto({required this.repairId, required String url})
    : super(url);
  final String repairId;
}

// ---------------------------------------------------------------------------

class DriveServiceHelper {
  // Drive API errors include the HTTP status in their string representation.
  // Only treat confirmed 404s as "not found" — transient errors should
  // propagate so callers can surface them rather than silently recreating
  // Drive resources and risking duplicates.
  static bool isDriveNotFound(Object e) {
    final msg = e.toString();
    return msg.contains('404') || msg.contains('notFound');
  }

  // Firebase Storage download URLs encode the full path as a single URL
  // segment after /o/ — decode it and take the last component (the filename).
  static String filenameFromUrl(String url) {
    try {
      final encoded = Uri.parse(url).pathSegments.last;
      return Uri.decodeComponent(encoded).split('/').last;
    } on Object catch (_) {
      return url.split('/').last.split('?').first;
    }
  }

  // Extracts the Firebase Storage path from a download URL, e.g.
  // "https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encoded-path}"
  // → "users/{uid}/sales/{saleId}/items/{itemId}/photos/{uuid}.jpg".
  // Used during restore to upload each photo back to its original path.
  static String storagePathFromUrl(String url) {
    try {
      final segments = Uri.parse(url).pathSegments;
      final oIndex = segments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < segments.length) {
        return Uri.decodeComponent(segments[oIndex + 1]);
      }
    } on Object catch (_) {}
    throw FormatException('Cannot extract Storage path from URL: $url');
  }

  // Walks the archive JSON to collect every photo URL along with enough
  // context to build its Drive folder path during backup. Malformed entries
  // are silently skipped — a missing photo is preferable to aborting the run.
  static List<PhotoEntry> extractPhotos(String jsonContent) {
    final entries = <PhotoEntry>[];
    try {
      final map = jsonDecode(jsonContent) as Map<String, dynamic>;

      for (final rawSale in map['sales'] as List? ?? const <dynamic>[]) {
        final sale = rawSale as Map<String, dynamic>;
        final saleId = sale['id'] as String? ?? '';
        for (final rawItem in sale['items'] as List? ?? const <dynamic>[]) {
          final item = rawItem as Map<String, dynamic>;
          final itemId = item['id'] as String? ?? '';
          for (final url
              in item['photoUrls'] as List? ?? const <dynamic>[]) {
            entries.add(
              SaleItemPhoto(saleId: saleId, itemId: itemId, url: url as String),
            );
          }
          for (final rawComp
              in item['components'] as List? ?? const <dynamic>[]) {
            final comp = rawComp as Map<String, dynamic>;
            final compId = comp['id'] as String? ?? '';
            for (final url
                in comp['photoUrls'] as List? ?? const <dynamic>[]) {
              entries.add(
                ComponentPhoto(
                  saleId: saleId,
                  itemId: itemId,
                  componentId: compId,
                  url: url as String,
                ),
              );
            }
          }
        }
      }

      for (final rawRepair
          in map['repairs'] as List? ?? const <dynamic>[]) {
        final repair = rawRepair as Map<String, dynamic>;
        final repairId = repair['id'] as String? ?? '';
        for (final url
            in repair['photoUrls'] as List? ?? const <dynamic>[]) {
          entries.add(RepairPhoto(repairId: repairId, url: url as String));
        }
      }
    } on Object catch (_) {
      // Return whatever was collected before the parse error.
    }
    return entries;
  }

  // Finds or creates a Drive folder by name under an optional parent.
  static Future<String> findOrCreateFolder(
    drive.DriveApi api,
    String name, {
    String? parentId,
  }) async {
    final existing = await findFolder(api, name, parentId: parentId);
    if (existing != null) return existing;

    final folder = await api.files.create(
      drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = parentId != null ? [parentId] : null,
      $fields: 'id',
    );
    return folder.id!;
  }

  // Finds a Drive folder by name under an optional parent.
  // Returns null if not found — never creates a folder.
  static Future<String?> findFolder(
    drive.DriveApi api,
    String name, {
    String? parentId,
  }) async {
    final parentClause = parentId != null
        ? "and '$parentId' in parents"
        : "and 'root' in parents";
    final result = await api.files.list(
      q: "name='$name' and mimeType='application/vnd.google-apps.folder' "
          '$parentClause and trashed=false',
      $fields: 'files(id)',
      spaces: 'drive',
    );
    final files = result.files;
    return (files != null && files.isNotEmpty) ? files.first.id! : null;
  }
}
