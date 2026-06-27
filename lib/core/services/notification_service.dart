import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';

enum NotificationDestination { settings }

const _kBackupChannelId = 'backup';
const _kRemindersChannelId = 'reminders';
const _kShoppingChannelId = 'shopping';
const _kBackupNotificationId = 1;

class NotificationService {
  const NotificationService._();

  static final pendingDestination =
      ValueNotifier<NotificationDestination?>(null);
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Call once from main() in the UI isolate, and once from callbackDispatcher
  // in the WorkManager isolate before posting a notification. Channel creation
  // is idempotent — subsequent calls with the same ID are no-ops on Android.
  static Future<void> initialize(AppStrings strings) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Check if the app was cold-started via a notification tap.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final response = launchDetails!.notificationResponse;
      if (response != null) _onTap(response);
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
      payload: 'settings',
    );
  }

  static void _onTap(NotificationResponse response) {
    final destination = switch (response.payload) {
      'settings' => NotificationDestination.settings,
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
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _kRemindersChannelId,
        strings.notificationChannelReminders,
      ),
    );
    // Low importance: the Shopping List notification is persistent and should
    // not make sound or pop up intrusively.
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _kShoppingChannelId,
        strings.shoppingList,
        importance: Importance.low,
      ),
    );
  }
}
