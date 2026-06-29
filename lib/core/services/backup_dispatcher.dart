import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/l10n/locale_settings.dart';
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/core/services/notification_service.dart';
import 'package:latitude_tracker/core/services/notification_settings.dart';
import 'package:latitude_tracker/core/services/reminder_task.dart';
import 'package:latitude_tracker/features/settings/services/drive_backup_service.dart';
import 'package:latitude_tracker/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const kBackupTaskName = 'driveBackup';

// Top-level entry point called by WorkManager in a fresh Dart isolate.
// Must be a top-level function — WorkManager cannot call instance methods.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, _) async {
    if (taskName != kBackupTaskName && taskName != kReminderTaskName) {
      return true;
    }

    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final prefs = await SharedPreferences.getInstance();

    // Guard: the user may have disabled notifications after this task was
    // enqueued (cancel() can race with a WorkManager dispatch on some OEMs).
    if (taskName == kReminderTaskName &&
        !NotificationSettings.enabledFromPrefs(prefs)) {
      return true;
    }

    final strings = AppStrings.forLanguageCode(
      LocaleSettings.languageCodeFrom(prefs),
    );
    await NotificationService.initialize(strings, checkLaunchDetails: false);

    // firebase_auth 4.x restores the persisted session asynchronously after
    // initializeApp() — currentUser may be null immediately even when valid.
    // Wait for the first auth state event before any Firestore access.
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (user == null) return true;

    if (taskName == kBackupTaskName) {
      await _runBackup(strings);
    } else {
      await _runReminder(user.uid, strings);
    }
    return true;
  });
}

Future<void> _runBackup(AppStrings strings) async {
  final result = await DriveBackupService().backupNow(silent: true);
  if (result case BackupError(:final error, :final stackTrace)) {
    logError(error, stackTrace);
    try {
      await NotificationService.showBackupFailure(strings);
    } on Object catch (e, st) {
      logError(e, st);
    }
  } else if (result case BackupPartialSuccess(:final failedPhotos)) {
    logError(
      StateError('Scheduled backup: $failedPhotos photo(s) failed to upload'),
      StackTrace.current,
    );
  }
}

Future<void> _runReminder(String uid, AppStrings strings) async {
  try {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    // 30-day lookback keeps the overdue count meaningful; sales older than
    // that are stale data the seller has likely already handled or archived.
    final lookbackStart = Timestamp.fromDate(
      startOfToday.subtract(const Duration(days: 30)),
    );
    final endOfWindow = Timestamp.fromDate(
      startOfToday.add(const Duration(days: 7)),
    );

    // Direct Firestore access is intentional here. SaleRepository requires
    // DemoMode.active, which depends on a running Flutter widget tree — not
    // available in a headless WorkManager isolate. This is the only place in
    // the codebase that bypasses the repository interface for this reason.
    // Firestore excludes docs where scheduledDate is null from inequality
    // queries, so no extra null filter is needed.
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sales')
        .where('scheduledDate', isGreaterThanOrEqualTo: lookbackStart)
        .where('scheduledDate', isLessThanOrEqualTo: endOfWindow)
        .get();

    var overdue = 0;
    var upcoming = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = data['scheduledDate'];
      if (ts is! Timestamp) continue;
      final shipmentStatus =
          (data['shipment'] as Map<String, dynamic>?)?['status'] as String?;
      if (shipmentStatus == 'delivered') continue;
      final sd = ts.toDate();
      final sdDay = DateTime(sd.year, sd.month, sd.day);
      if (sdDay.isBefore(startOfToday)) {
        overdue++;
      } else {
        upcoming++;
      }
    }

    if (overdue > 0 || upcoming > 0) {
      await NotificationService.showSaleReminder(
        strings,
        overdue: overdue,
        upcoming: upcoming,
      );
    }
  } on Object catch (e, st) {
    // Log but do not rethrow. WorkManager treats an exception as task failure
    // and applies exponential back-off, permanently drifting the reminder away
    // from the user's configured time. Returning true (implicit) keeps the
    // periodic schedule intact.
    logError(e, st);
  }
}
