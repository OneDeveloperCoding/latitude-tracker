import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/features/settings/services/archive_service.dart';
import 'package:latitude_tracker/features/settings/services/drive_service_helper.dart';

sealed class RestoreResult {
  const RestoreResult();
}

class RestoreSuccess extends RestoreResult {
  const RestoreSuccess(this.imported);
  final ImportResult imported;
}

class RestorePartialSuccess extends RestoreResult {
  const RestorePartialSuccess({
    required this.imported,
    required this.failedPhotos,
    required this.failedYears,
  });
  final ImportResult imported;
  final int failedPhotos;
  final int failedYears;
}

// No JSON files found in Latitude Tracker Backup/data/.
class RestoreNoBackupsFound extends RestoreResult {
  const RestoreNoBackupsFound();
}

// User dismissed the Drive scope consent dialog.
class RestoreScopeDenied extends RestoreResult {
  const RestoreScopeDenied();
}

class RestoreError extends RestoreResult {
  const RestoreError(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

enum RestorePhase { data, photos }

typedef RestoreProgressCallback =
    void Function(RestorePhase phase, int done, int total);

class DriveRestoreService {
  DriveRestoreService({ArchiveService? archiveService})
    : _archiveService = archiveService ?? ArchiveService();

  final ArchiveService _archiveService;

  Future<RestoreResult> restoreFromDrive({
    RestoreProgressCallback? onProgress,
  }) async {
    try {
      final result = await DriveServiceHelper.withDriveApi<RestoreResult>(
        (api) => _runRestore(api, onProgress),
      );
      return result ?? const RestoreScopeDenied();
    } on Object catch (e, st) {
      return RestoreError(e, st);
    }
  }

  Future<RestoreResult> _runRestore(
    drive.DriveApi api,
    RestoreProgressCallback? onProgress,
  ) async {
    onProgress?.call(RestorePhase.data, 0, 0);

    // Locate the backup folder structure — never create folders during restore.
    final rootFolderId = await DriveServiceHelper.findFolder(
      api,
      kBackupFolderName,
    );
    if (rootFolderId == null) return const RestoreNoBackupsFound();

    final dataFolderId = await DriveServiceHelper.findFolder(
      api,
      kDataFolderName,
      parentId: rootFolderId,
    );
    if (dataFolderId == null) return const RestoreNoBackupsFound();

    final jsonFiles = await _listJsonFiles(api, dataFolderId);
    if (jsonFiles.isEmpty) return const RestoreNoBackupsFound();

    // Phase 1: download and import each JSON file.
    // Failed years are counted and skipped — the idempotent import means a
    // retry (tap Restore again) will naturally skip already-imported data and
    // only attempt the previously failed years.
    var salesImported = 0;
    var buyersImported = 0;
    var repairsImported = 0;
    var skipped = 0;
    var failedYears = 0;
    final allPhotos = <PhotoEntry>[];

    for (var i = 0; i < jsonFiles.length; i++) {
      onProgress?.call(RestorePhase.data, i, jsonFiles.length);
      final (fileId, fileName) = jsonFiles[i];
      try {
        final content = await _downloadText(api, fileId);
        // Decode JSON once so photos can be extracted and data imported
        // without a second jsonDecode call on the same string.
        final Map<String, dynamic> decoded;
        try {
          decoded = jsonDecode(content) as Map<String, dynamic>;
        } on Object catch (e, st) {
          logError(e, st);
          failedYears++;
          continue;
        }
        // Extract photos before attempting import so a failed import does not
        // lose the photo list for this year.
        allPhotos.addAll(DriveServiceHelper.extractPhotosFromMap(decoded));
        final archive = ArchiveService.parseArchive(content);
        if (archive == null) {
          throw FormatException('Could not parse backup file: $fileName');
        }
        final result = await _archiveService.importArchive(archive);
        salesImported += result.salesImported;
        buyersImported += result.buyersImported;
        repairsImported += result.repairsImported;
        skipped += result.skipped;
      } on Object catch (e, st) {
        logError(e, st);
        failedYears++;
      }
    }
    onProgress?.call(RestorePhase.data, jsonFiles.length, jsonFiles.length);

    // Phase 2: restore photos.
    // A missing photos/ folder is not an error when there are no photos to
    // restore. If photos are expected but the folder is absent (e.g. the user
    // deleted it from Drive), count them all as failed so the caller surfaces
    // RestorePartialSuccess instead of RestoreSuccess.
    final photosFolderId = await DriveServiceHelper.findFolder(
      api,
      kPhotosFolderName,
      parentId: rootFolderId,
    );
    final int failedPhotos;
    if (allPhotos.isEmpty) {
      failedPhotos = 0;
    } else if (photosFolderId == null) {
      failedPhotos = allPhotos.length;
    } else {
      failedPhotos = await _runPhotoRestore(api, allPhotos, onProgress);
    }

    final imported = ImportResult(
      salesImported: salesImported,
      buyersImported: buyersImported,
      repairsImported: repairsImported,
      skipped: skipped,
    );

    if (failedYears == 0 && failedPhotos == 0) return RestoreSuccess(imported);
    return RestorePartialSuccess(
      imported: imported,
      failedPhotos: failedPhotos,
      failedYears: failedYears,
    );
  }

  // Returns the number of photos that failed to restore.
  Future<int> _runPhotoRestore(
    drive.DriveApi api,
    List<PhotoEntry> photos,
    RestoreProgressCallback? onProgress,
  ) async {
    // Build a {filename → fileId} map from Drive in one paginated sweep so
    // individual photo lookups are O(1) in-memory rather than O(1) Drive calls.
    // The global appProperties query is intentional: photos are nested several
    // levels deep under photos/ (sales/{id}/{id}/{uuid}.jpg etc.), making a
    // parent-folder constraint impractical without recursive traversal.
    final uuidToFileId = await _buildUuidToFileIdMap(api);

    // Firebase Auth session can expire between Phase 1 (data import) and
    // Phase 2 (photo restore). Guard here so a null currentUser returns
    // RestorePartialSuccess with the Phase 1 data intact rather than crashing.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return photos.length;

    final storage = FirebaseStorage.instance;
    var failed = 0;

    for (var i = 0; i < photos.length; i++) {
      onProgress?.call(RestorePhase.photos, i, photos.length);
      final entry = photos[i];
      final filename = DriveServiceHelper.filenameFromUrl(entry.url);
      final fileId = uuidToFileId[filename];
      // Photo is in the JSON but absent from Drive (e.g. deleted by the user).
      // Skip silently — we cannot restore what is not there.
      if (fileId == null) continue;

      try {
        final storagePath = DriveServiceHelper.storagePathFromUrl(entry.url);
        // Replace the UID segment with the current user's UID to handle the
        // edge case where the backup was made under a different UID.
        final correctedPath = _replaceUid(storagePath, uid);
        final ref = storage.ref(correctedPath);

        // Skip photos already present in Storage — restore is idempotent.
        try {
          await ref.getMetadata();
          continue;
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') rethrow;
        }

        final media = await api.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;
        await ref.putData(
          await _collectBytes(media.stream),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } on Object catch (e, st) {
        logError(e, st);
        failed++;
      }
    }
    onProgress?.call(RestorePhase.photos, photos.length, photos.length);
    return failed;
  }

  // Queries Drive for all files tagged isUploaded=true and returns a map of
  // {filename → fileId}. One paginated sweep is O(n/1000) Drive calls.
  Future<Map<String, String>> _buildUuidToFileIdMap(drive.DriveApi api) async {
    final map = <String, String>{};
    String? pageToken;
    do {
      final result = await api.files.list(
        q: "appProperties has {key='$kIsUploadedKey' "
            "and value='$kIsUploadedValue'} and trashed=false",
        $fields: 'nextPageToken,files(id,name)',
        spaces: 'drive',
        pageToken: pageToken,
      );
      for (final f in result.files ?? <drive.File>[]) {
        if (f.name != null && f.id != null) map[f.name!] = f.id!;
      }
      pageToken = result.nextPageToken;
    } while (pageToken != null);
    return map;
  }

  // Lists all JSON files in the given Drive folder, returning (fileId, name)
  // pairs. Does not paginate — the data/ folder is expected to contain at most
  // a handful of files (one per year).
  Future<List<(String, String)>> _listJsonFiles(
    drive.DriveApi api,
    String folderId,
  ) async {
    final result = await api.files.list(
      q: "mimeType='application/json' and '$folderId' in parents "
          'and trashed=false',
      $fields: 'files(id,name)',
      spaces: 'drive',
    );
    return [
      for (final f in result.files ?? <drive.File>[])
        if (f.id != null && f.name != null) (f.id!, f.name!),
    ];
  }

  // Downloads a Drive file and returns its content as a UTF-8 string.
  // allowMalformed: true substitutes U+FFFD for bad byte sequences rather than
  // throwing, giving the JSON decoder a chance to recover when the file
  // structure is intact despite minor encoding issues.
  Future<String> _downloadText(drive.DriveApi api, String fileId) async {
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    return utf8.decode(
      await _collectBytes(media.stream),
      allowMalformed: true,
    );
  }

  // Collects a Stream<List<int>> into a single Uint8List without boxing bytes
  // as Dart ints (which would cost ~8× the data size on a 64-bit VM).
  static Future<Uint8List> _collectBytes(Stream<List<int>> stream) async {
    final chunks = await stream.toList();
    final totalLength = chunks.fold<int>(0, (acc, c) => acc + c.length);
    final bytes = Uint8List(totalLength);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return bytes;
  }

  // Replaces the UID segment in a Storage path of the form
  // "users/{uid}/..." with the current user's UID. Guards against the edge
  // case where the backup was created under a different Firebase UID.
  static String _replaceUid(String path, String uid) {
    final parts = path.split('/');
    if (parts.length >= 2 && parts[0] == 'users') {
      parts[1] = uid;
      return parts.join('/');
    }
    return path;
  }
}
