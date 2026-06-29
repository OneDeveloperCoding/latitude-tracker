import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/services/reminder_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class NotificationSettings {
  const NotificationSettings._();

  static const _enabledKey = 'notif_reminder_enabled';
  static const _hourKey = 'notif_reminder_hour';
  static const _minuteKey = 'notif_reminder_minute';

  // Reads the enabled state directly from prefs — used by the WorkManager
  // background isolate where ValueNotifiers are not initialised.
  static bool enabledFromPrefs(SharedPreferences prefs) =>
      prefs.getBool(_enabledKey) ?? false;

  static final enabled = ValueNotifier<bool>(false);
  static final timeOfDay = ValueNotifier<TimeOfDay>(
    const TimeOfDay(hour: 9, minute: 0),
  );

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_enabledKey) ?? false;
    timeOfDay.value = TimeOfDay(
      hour: prefs.getInt(_hourKey) ?? 9,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
  }

  // Called once after WorkManager is initialised to re-register the reminder
  // task if it was enabled before this launch. Uses keep so cold-start app
  // opens do not reset the 24-hour WorkManager timer — only explicit user
  // changes (setEnabled / setTime) use replace.
  static Future<void> registerIfEnabled() async {
    if (enabled.value) {
      await ReminderTask.schedule(
        timeOfDay.value,
        policy: ExistingPeriodicWorkPolicy.keep,
      );
    }
  }

  static Future<void> setEnabled({required bool value}) async {
    enabled.value = value; // optimistic — UI reflects intent immediately
    final prefs = await SharedPreferences.getInstance();
    try {
      if (value) {
        await ReminderTask.schedule(timeOfDay.value);
      } else {
        await ReminderTask.cancel();
      }
      await prefs.setBool(_enabledKey, value);
    } catch (_) {
      enabled.value = !value; // roll back if scheduling fails
      rethrow;
    }
  }

  static Future<void> setTime(TimeOfDay value) async {
    timeOfDay.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, value.hour);
    await prefs.setInt(_minuteKey, value.minute);
    if (enabled.value) await ReminderTask.schedule(value);
  }
}
