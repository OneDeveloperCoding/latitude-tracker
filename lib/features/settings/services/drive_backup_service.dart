import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/features/settings/services/archive_service.dart';
import 'package:latitude_tracker/features/settings/services/drive_service_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:latitude_tracker/features/settings/services/drive_service_helper.dart'
    show ComponentPhoto, PhotoEntry, RepairPhoto, SaleItemPhoto;

const _kBackupFloorYear = 2026;
const _kLastBackupKey = 'drive_backup_last_success';
const _kRootFolderIdKey = 'drive_backup_root_folder_id';
const _kDataFileIdPrefix = 'drive_backup_file_';

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
      final result = await DriveServiceHelper.withDriveApi<BackupResult>(
        (api) async {
          final failedPhotos = await _runBackup(api, onProgress);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            _kLastBackupKey,
            DateTime.now().toIso8601String(),
          );
          return failedPhotos > 0
              ? BackupPartialSuccess(failedPhotos)
              : const BackupSuccess();
        },
        silent: silent,
      );
      return result ?? const BackupScopeDenied();
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
      kBackupFolderName,
    );
    final dataFolderId = await DriveServiceHelper.findOrCreateFolder(
      api,
      kDataFolderName,
      parentId: backupFolderId,
    );

    final cachedBuyers = await _archiveService.fetchBuyersData();
    final allPhotos = <PhotoEntry>[];
    final currentYear = DateTime.now().year;
    for (var year = currentYear; year >= _kBackupFloorYear; year--) {
      final file = await _archiveService.exportYear(
        year,
        cachedBuyers: cachedBuyers,
      );
      final content = await file.readAsString();
      // Always scan to the floor year — a gap year (no sales/repairs) must
      // not stop the sweep, as data from earlier years would be silently lost.
      if (_isEmptyArchive(content)) continue;
      await _uploadOrUpdateCachedFile(
        api,
        prefs,
        dataFolderId,
        DriveServiceHelper.backupFileName(year),
        content,
        '$_kDataFileIdPrefix$year',
      );
      allPhotos.addAll(DriveServiceHelper.extractPhotos(content));
    }

    final photosFolderId = await DriveServiceHelper.findOrCreateFolder(
      api,
      kPhotosFolderName,
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
      } on Object catch (e) {
        // Only evict the cache on a confirmed 404 — transient network errors
        // should propagate so the run fails as BackupError, not silently
        // clear a valid ID and risk creating a duplicate folder.
        if (!DriveServiceHelper.isDriveNotFound(e)) rethrow;
        await prefs.remove(cacheKey);
      }
    }
    final id = await DriveServiceHelper.findOrCreateFolder(
      api,
      name,
      parentId: parentId,
    );
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
    // Stream.value is single-subscription and is exhausted after the first
    // read — create a fresh Media for each Drive API call so a failed cached
    // update doesn't corrupt the fallback search-and-create path.
    drive.Media buildMedia() => drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    final cachedId = prefs.getString(cacheKey);
    if (cachedId != null) {
      try {
        await api.files.update(
          drive.File()..mimeType = 'application/json',
          cachedId,
          uploadMedia: buildMedia(),
        );
        return;
      } on Object catch (e) {
        if (!DriveServiceHelper.isDriveNotFound(e)) rethrow;
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
      await api.files.update(
        drive.File()..mimeType = 'application/json',
        fileId,
        uploadMedia: buildMedia(),
      );
    } else {
      final created = await api.files.create(
        drive.File()
          ..name = fileName
          ..mimeType = 'application/json'
          ..parents = [parentId],
        uploadMedia: buildMedia(),
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
      final filename = DriveServiceHelper.filenameFromUrl(entry.url);
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
        q: "appProperties has {key='$kIsUploadedKey' "
            "and value='$kIsUploadedValue'} and trashed=false",
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
        kSalesFolderName,
        saleId,
        itemId,
      ],
      ComponentPhoto(:final saleId, :final itemId, :final componentId) => [
        kComponentsFolderName,
        saleId,
        itemId,
        componentId,
      ],
      RepairPhoto(:final repairId) => [kRepairsFolderName, repairId],
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
        parentId = await DriveServiceHelper.findOrCreateFolder(
          api,
          part,
          parentId: parentId,
        );
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
        ..appProperties = {kIsUploadedKey: kIsUploadedValue},
      uploadMedia: drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'image/jpeg',
      ),
      $fields: 'id',
    );
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
}
