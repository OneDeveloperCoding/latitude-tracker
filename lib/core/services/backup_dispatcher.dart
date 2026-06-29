import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/l10n/locale_settings.dart';
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/core/services/notification_service.dart';
import 'package:latitude_tracker/core/services/reminder_task.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
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
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfWindow = Timestamp.fromDate(
    startOfToday.add(const Duration(days: 7)),
  );

  // Query only sales that have a scheduledDate within the next 7 days
  // (Firestore excludes null scheduledDate docs from inequality queries).
  // Overdue sales (past startOfToday) are included because their scheduledDate
  // is less than endOfWindow.
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('sales')
      .where('scheduledDate', isLessThanOrEqualTo: endOfWindow)
      .get();

  var overdue = 0;
  var upcoming = 0;
  for (final doc in snap.docs) {
    final sale = Sale.fromFirestore(doc);
    if (sale.shipment.status == ShipmentStatus.delivered) continue;
    final sd = sale.scheduledDate;
    if (sd == null) continue;
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
}
