import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/services/reminder_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  const NotificationSettings._();

  static const _enabledKey = 'notif_reminder_enabled';
  static const _hourKey = 'notif_reminder_hour';
  static const _minuteKey = 'notif_reminder_minute';

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

  // Called once after WorkManager is initialized (via BackupTask.register()) to
  // re-register the reminder task if it was already enabled before this launch.
  static Future<void> registerIfEnabled() async {
    if (enabled.value) await ReminderTask.schedule(timeOfDay.value);
  }

  static Future<void> setEnabled({required bool value}) async {
    enabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (value) {
      await ReminderTask.schedule(timeOfDay.value);
    } else {
      await ReminderTask.cancel();
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
