import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/features/settings/services/drive_backup_service.dart';
import 'package:latitude_tracker/firebase_options.dart';
import 'package:workmanager/workmanager.dart';

const kBackupTaskName = 'driveBackup';

// Top-level entry point called by WorkManager in a fresh Dart isolate.
// Must be a top-level function — WorkManager cannot call instance methods.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, _) async {
    if (taskName != kBackupTaskName) return true;

    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // firebase_auth 4.x restores the persisted session asynchronously after
    // initializeApp() — currentUser may be null immediately even when valid.
    // Wait for the first auth state event before any Firestore access.
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (user == null) return true;

    final result = await DriveBackupService().backupNow(silent: true);
    if (result case BackupError(:final error, :final stackTrace)) {
      logError(error, stackTrace);
    } else if (result case BackupPartialSuccess(:final failedPhotos)) {
      logError(
        StateError('Scheduled backup: $failedPhotos photo(s) failed to upload'),
        StackTrace.current,
      );
    }
    return true;
  });
}
