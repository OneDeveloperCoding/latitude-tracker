import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';

enum NotificationDestination { settings }

const _kBackupChannelId = 'backup';
const _kBackupNotificationId = 1;
const _kSettingsPayload = 'settings';

class NotificationService {
  const NotificationService._();

  static final pendingDestination =
      ValueNotifier<NotificationDestination?>(null);
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Call once from main() in the UI isolate with checkLaunchDetails: true
  // (default), and from callbackDispatcher with checkLaunchDetails: false —
  // the launch-details API interrogates the Android Activity's launch intent,
  // which does not exist in a headless WorkManager isolate.
  // Channel creation is idempotent — same-ID calls are no-ops on Android.
  static Future<void> initialize(
    AppStrings strings, {
    bool checkLaunchDetails = true,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    if (checkLaunchDetails) {
      // flutter_local_notifications does not replay onDidReceiveNotification-
      // Response on cold start — launch details must be inspected manually.
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final response = launchDetails!.notificationResponse;
        if (response != null) _onTap(response);
      }
    }

    await _createChannels(strings);
  }

  // Returns true if permission was already granted or just granted by the user.
  // On Android < 13 always returns true (permission not required).
  // Shows the system dialog only once — subsequent calls are no-ops.
  static Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.requestNotificationsPermission() ?? true;
  }

  static Future<void> showBackupFailure(AppStrings strings) async {
    await _plugin.show(
      id: _kBackupNotificationId,
      title: strings.backupFailureTitle,
      body: strings.backupFailureBody,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _kBackupChannelId,
          strings.backup,
        ),
      ),
      payload: _kSettingsPayload,
    );
  }

  static void _onTap(NotificationResponse response) {
    final destination = switch (response.payload) {
      _kSettingsPayload => NotificationDestination.settings,
      _ => null,
    };
    if (destination != null) pendingDestination.value = destination;
  }

  static Future<void> _createChannels(AppStrings strings) async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _kBackupChannelId,
        strings.backup,
      ),
    );
    // Additional channels (reminders, shopping) are registered when
    // issues #146 and #185 land, to avoid surfacing unexplained categories
    // in Android App Info → Notifications before those features ship.
  }
}
