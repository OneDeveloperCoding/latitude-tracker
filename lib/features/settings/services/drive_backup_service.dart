import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/features/auth/services/google_auth_service.dart';
import 'package:latitude_tracker/features/settings/services/archive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBackupFloorYear = 2026;
const _kLastBackupKey = 'drive_backup_last_success';
const _kRootFolderIdKey = 'drive_backup_root_folder_id';
const _kDataFileIdPrefix = 'drive_backup_file_';
const _kBackupFolderName = 'Latitude Tracker Backup';
const _kDataFolderName = 'data';
const _kPhotosFolderName = 'photos';
const _kSalesFolderName = 'sales';
const _kComponentsFolderName = 'components';
const _kRepairsFolderName = 'repairs';
const _kIsUploadedKey = 'isUploaded';
const _kIsUploadedValue = 'true';

sealed class BackupResult {
  const BackupResult();
}

class BackupSuccess extends BackupResult {
  const BackupSuccess();
}

class BackupPartialSuccess extends BackupResult {
  const BackupPartialSuccess(this.failedPhotos);
  final int failedPhotos;
}

// User dismissed the Drive scope consent dialog.
class BackupScopeDenied extends BackupResult {
  const BackupScopeDenied();
}

class BackupError extends BackupResult {
  const BackupError(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

enum BackupPhase { data, photos }

typedef BackupProgressCallback =
    void Function(BackupPhase phase, int done, int total);

// ---------------------------------------------------------------------------
// Photo entry types — carry enough context to build the Drive folder path.
// Public so that @visibleForTesting helpers can reference them from tests.
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

class DriveBackupService {
  DriveBackupService({ArchiveService? archiveService})
    : _archiveService = archiveService ?? ArchiveService();

  final ArchiveService _archiveService;

  Future<DateTime?> lastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kLastBackupKey);
    return value != null ? DateTime.tryParse(value) : null;
  }

  // Set silent: true when calling from a background task — skips the scope
  // consent dialog, which cannot be shown without an active Activity.
  Future<BackupResult> backupNow({
    BackupProgressCallback? onProgress,
    bool silent = false,
  }) async {
    try {
      final googleSignIn = GoogleAuthService.googleSignIn;

      // Restore the Dart-layer currentUser from the Android native cache.
      // Without this, authenticatedClient() returns null after every app
      // restart because GoogleSignIn._currentUser is not persisted across
      // cold starts, even though the Firebase Auth session and the Android
      // native sign-in cache survive.
      await googleSignIn.signInSilently();

      if (!silent) {
        final granted = await googleSignIn.requestScopes(
          [drive.DriveApi.driveFileScope],
        );
        if (!granted) return const BackupScopeDenied();
      }

      final client = await googleSignIn.authenticatedClient();
      if (client == null) return const BackupScopeDenied();

      var failedPhotos = 0;
      try {
        failedPhotos = await _runBackup(drive.DriveApi(client), onProgress);
      } finally {
        client.close();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastBackupKey, DateTime.now().toIso8601String());

      return failedPhotos > 0
          ? BackupPartialSuccess(failedPhotos)
          : const BackupSuccess();
    } on Object catch (e, st) {
      return BackupError(e, st);
    }
  }

  // Returns the number of photos that failed to upload.
  Future<int> _runBackup(
    drive.DriveApi api,
    BackupProgressCallback? onProgress,
  ) async {
    onProgress?.call(BackupPhase.data, 0, 0);

    final prefs = await SharedPreferences.getInstance();
    final backupFolderId = await _getOrCreateCachedFolder(
      api,
      prefs,
      _kRootFolderIdKey,
      _kBackupFolderName,
    );
    final dataFolderId = await _findOrCreateFolder(
      api,
      _kDataFolderName,
      parentId: backupFolderId,
    );

    final cachedBuyers = await _archiveService.fetchBuyersData();
    final allPhotos = <PhotoEntry>[];
    var seenNonEmpty = false;
    final currentYear = DateTime.now().year;
    for (var year = currentYear; year >= _kBackupFloorYear; year--) {
      final file = await _archiveService.exportYear(
        year,
        cachedBuyers: cachedBuyers,
      );
      final content = await file.readAsString();
      if (_isEmptyArchive(content)) {
        // Skip empty leading years (e.g. January before the first sale).
        // Stop only once we've passed the end of contiguous data.
        if (seenNonEmpty) break;
        continue;
      }
      seenNonEmpty = true;
      await _uploadOrUpdateCachedFile(
        api,
        prefs,
        dataFolderId,
        'latitude_tracker_$year.json',
        content,
        '$_kDataFileIdPrefix$year',
      );
      allPhotos.addAll(extractPhotos(content));
    }

    final photosFolderId = await _findOrCreateFolder(
      api,
      _kPhotosFolderName,
      parentId: backupFolderId,
    );
    return _runPhotoBackup(api, photosFolderId, allPhotos, onProgress);
  }

  // Uses a cached Drive folder ID to skip the search round-trip on subsequent
  // runs. Falls back to search-and-create on cache miss or if the folder was
  // deleted from Drive.
  Future<String> _getOrCreateCachedFolder(
    drive.DriveApi api,
    SharedPreferences prefs,
    String cacheKey,
    String name, {
    String? parentId,
  }) async {
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        await api.files.get(cached, $fields: 'id');
        return cached;
      } on Object {
        // Folder no longer exists in Drive — recreate below.
        await prefs.remove(cacheKey);
      }
    }
    final id = await _findOrCreateFolder(api, name, parentId: parentId);
    await prefs.setString(cacheKey, id);
    return id;
  }

  // Updates a Drive file by cached ID when available, avoiding the
  // search-then-create race between concurrent runs. Caches the file ID after
  // first creation so future runs update by ID directly.
  Future<void> _uploadOrUpdateCachedFile(
    drive.DriveApi api,
    SharedPreferences prefs,
    String parentId,
    String fileName,
    String content,
    String cacheKey,
  ) async {
    final bytes = utf8.encode(content);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    final cachedId = prefs.getString(cacheKey);
    if (cachedId != null) {
      try {
        await api.files.update(drive.File(), cachedId, uploadMedia: media);
        return;
      } on Object {
        // File no longer exists in Drive — fall through to recreate.
        await prefs.remove(cacheKey);
      }
    }

    final result = await api.files.list(
      q: "name='$fileName' and '$parentId' in parents and trashed=false",
      $fields: 'files(id)',
      spaces: 'drive',
    );

    final String fileId;
    if (result.files != null && result.files!.isNotEmpty) {
      fileId = result.files!.first.id!;
      await api.files.update(drive.File(), fileId, uploadMedia: media);
    } else {
      final created = await api.files.create(
        drive.File()
          ..name = fileName
          ..parents = [parentId],
        uploadMedia: media,
        $fields: 'id',
      );
      fileId = created.id!;
    }
    await prefs.setString(cacheKey, fileId);
  }

  Future<int> _runPhotoBackup(
    drive.DriveApi api,
    String photosFolderId,
    List<PhotoEntry> photos,
    BackupProgressCallback? onProgress,
  ) async {
    if (photos.isEmpty) return 0;

    final uploaded = await _buildUploadedSet(api);
    // Folder IDs are cached per run to avoid redundant Drive API calls.
    final folderCache = <String, String>{};

    var failed = 0;
    for (var i = 0; i < photos.length; i++) {
      onProgress?.call(BackupPhase.photos, i, photos.length);
      final entry = photos[i];
      final filename = filenameFromUrl(entry.url);
      if (uploaded.contains(filename)) continue;

      try {
        final folderId = await _resolvePhotoFolder(
          api,
          photosFolderId,
          entry,
          folderCache,
        );
        await _uploadPhoto(api, folderId, filename, entry.url);
      } on Object catch (e, st) {
        logError(e, st);
        failed++;
      }
    }
    onProgress?.call(BackupPhase.photos, photos.length, photos.length);
    return failed;
  }

  // Queries Drive for all files tagged isUploaded=true (our app's photos) and
  // returns a Set of their filenames (UUIDs). One paginated sweep replaces
  // per-photo existence checks, reducing Drive API calls from O(n) to O(n/1000).
  Future<Set<String>> _buildUploadedSet(drive.DriveApi api) async {
    final names = <String>{};
    String? pageToken;
    do {
      final result = await api.files.list(
        q: "appProperties has {key='$_kIsUploadedKey' "
            "and value='$_kIsUploadedValue'} and trashed=false",
        $fields: 'nextPageToken,files(name)',
        spaces: 'drive',
        pageToken: pageToken,
      );
      for (final f in result.files ?? <drive.File>[]) {
        if (f.name != null) names.add(f.name!);
      }
      pageToken = result.nextPageToken;
    } while (pageToken != null);
    return names;
  }

  // Resolves (finds or creates) the Drive folder for a photo entry, using
  // folderCache to avoid redundant API calls within a single backup run.
  Future<String> _resolvePhotoFolder(
    drive.DriveApi api,
    String photosFolderId,
    PhotoEntry entry,
    Map<String, String> folderCache,
  ) async {
    final parts = switch (entry) {
      SaleItemPhoto(:final saleId, :final itemId) => [
        _kSalesFolderName,
        saleId,
        itemId,
      ],
      ComponentPhoto(:final saleId, :final itemId, :final componentId) => [
        _kComponentsFolderName,
        saleId,
        itemId,
        componentId,
      ],
      RepairPhoto(:final repairId) => [_kRepairsFolderName, repairId],
    };

    var parentId = photosFolderId;
    final pathParts = <String>[];
    for (final part in parts) {
      pathParts.add(part);
      final cacheKey = pathParts.join('/');
      final cached = folderCache[cacheKey];
      if (cached != null) {
        parentId = cached;
      } else {
        parentId = await _findOrCreateFolder(api, part, parentId: parentId);
        folderCache[cacheKey] = parentId;
      }
    }
    return parentId;
  }

  Future<void> _uploadPhoto(
    drive.DriveApi api,
    String folderId,
    String filename,
    String url,
  ) async {
    final bytes = await FirebaseStorage.instance.refFromURL(url).getData();
    // Null means the object exists in Storage metadata but has no content.
    // Treat as a failure so it surfaces in BackupPartialSuccess rather than
    // being silently skipped and retried on every future run.
    if (bytes == null) throw StateError('getData() returned null for: $url');

    await api.files.create(
      drive.File()
        ..name = filename
        ..parents = [folderId]
        ..appProperties = {_kIsUploadedKey: _kIsUploadedValue},
      uploadMedia: drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'image/jpeg',
      ),
      $fields: 'id',
    );
  }

  Future<String> _findOrCreateFolder(
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

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }

    final folder = await api.files.create(
      drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = parentId != null ? [parentId] : null,
      $fields: 'id',
    );
    return folder.id!;
  }

  // Stops the year sweep when a year has neither sales nor repairs.
  // Buyers are not year-scoped so their presence does not count as "data".
  static bool _isEmptyArchive(String jsonContent) {
    try {
      final map = jsonDecode(jsonContent) as Map<String, dynamic>;
      final sales = (map['sales'] as List?)?.length ?? 0;
      final repairs = (map['repairs'] as List?)?.length ?? 0;
      return sales == 0 && repairs == 0;
    } on Object catch (_) {
      return false;
    }
  }

  // Walks the archive JSON (already in memory from the data phase) to collect
  // every photo URL along with enough context to build its Drive folder path.
  // Malformed entries are silently skipped — a missing photo is preferable to
  // aborting the entire backup run.
  @visibleForTesting
  static List<PhotoEntry> extractPhotos(String jsonContent) {
    final entries = <PhotoEntry>[];
    try {
      final map = jsonDecode(jsonContent) as Map<String, dynamic>;

      for (final rawSale in map['sales'] as List? ?? const <dynamic>[]) {
        final sale = rawSale as Map<String, dynamic>;
        final saleId = sale['id'] as String? ?? '';
        for (final rawItem
            in sale['items'] as List? ?? const <dynamic>[]) {
          final item = rawItem as Map<String, dynamic>;
          final itemId = item['id'] as String? ?? '';
          for (final url
              in item['photoUrls'] as List? ?? const <dynamic>[]) {
            entries.add(
              SaleItemPhoto(
                saleId: saleId,
                itemId: itemId,
                url: url as String,
              ),
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
          entries.add(
            RepairPhoto(repairId: repairId, url: url as String),
          );
        }
      }
    } on Object catch (_) {
      // Return whatever was collected before the parse error.
    }
    return entries;
  }

  // Firebase Storage download URLs encode the full path as a single URL
  // segment after /o/ — decode it and take the last component (the filename).
  @visibleForTesting
  static String filenameFromUrl(String url) {
    try {
      final encoded = Uri.parse(url).pathSegments.last;
      return Uri.decodeComponent(encoded).split('/').last;
    } on Object catch (_) {
      // Fallback for unexpected URL formats.
      return url.split('/').last.split('?').first;
    }
  }
}
