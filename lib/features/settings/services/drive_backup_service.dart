import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:latitude_tracker/features/auth/services/google_auth_service.dart';
import 'package:latitude_tracker/features/settings/services/archive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBackupFloorYear = 2024;
const _kLastBackupKey = 'drive_backup_last_success';
const _kBackupFolderName = 'Latitude Tracker Backup';
const _kDataFolderName = 'data';

sealed class BackupResult {
  const BackupResult();
}

class BackupSuccess extends BackupResult {
  const BackupSuccess();
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

class DriveBackupService {
  DriveBackupService({ArchiveService? archiveService})
      : _archiveService = archiveService ?? ArchiveService();

  final ArchiveService _archiveService;

  Future<DateTime?> lastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kLastBackupKey);
    return value != null ? DateTime.tryParse(value) : null;
  }

  Future<BackupResult> backupNow() async {
    try {
      final googleSignIn = GoogleAuthService.googleSignIn;

      // Restore the Dart-layer currentUser from the Android native cache.
      // Without this, authenticatedClient() returns null after every app
      // restart because GoogleSignIn._currentUser is not persisted across
      // cold starts, even though the Firebase Auth session and the Android
      // native sign-in cache survive.
      await googleSignIn.signInSilently();

      final granted =
          await googleSignIn.requestScopes([drive.DriveApi.driveFileScope]);
      if (!granted) return const BackupScopeDenied();

      final client = await googleSignIn.authenticatedClient();
      if (client == null) return const BackupScopeDenied();
      try {
        await _runBackup(drive.DriveApi(client));
      } finally {
        client.close();
      }

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(_kLastBackupKey, now.toIso8601String());
      return const BackupSuccess();
    } on Object catch (e, st) {
      return BackupError(e, st);
    }
  }

  Future<void> _runBackup(drive.DriveApi api) async {
    final backupFolderId =
        await _findOrCreateFolder(api, _kBackupFolderName);
    final dataFolderId = await _findOrCreateFolder(
      api,
      _kDataFolderName,
      parentId: backupFolderId,
    );

    final currentYear = DateTime.now().year;
    for (var year = currentYear; year >= _kBackupFloorYear; year--) {
      final file = await _archiveService.exportYear(year);
      final content = await file.readAsString();
      // Assumes data is contiguous: stop on the first empty year rather than
      // scanning all the way to _kBackupFloorYear. A genuine gap year would
      // silently skip earlier data — accepted trade-off over extra Firestore
      // reads per run.
      if (_isEmptyArchive(content)) break;
      await _uploadOrUpdateFile(
        api,
        dataFolderId,
        'latitude_tracker_$year.json',
        content,
      );
    }
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

  Future<void> _uploadOrUpdateFile(
    drive.DriveApi api,
    String parentId,
    String fileName,
    String content,
  ) async {
    final result = await api.files.list(
      q: "name='$fileName' and '$parentId' in parents and trashed=false",
      $fields: 'files(id)',
      spaces: 'drive',
    );

    final bytes = utf8.encode(content);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      await api.files.update(
        drive.File(),
        result.files!.first.id!,
        uploadMedia: media,
      );
    } else {
      await api.files.create(
        drive.File()
          ..name = fileName
          ..parents = [parentId],
        uploadMedia: media,
      );
    }
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
