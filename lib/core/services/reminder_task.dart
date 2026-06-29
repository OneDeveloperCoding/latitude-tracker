import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

const kReminderTaskName = 'saleReminder';
const _kTaskUniqueName = 'daily-sale-reminder';

class ReminderTask {
  const ReminderTask._();

  static Future<void> schedule(
    TimeOfDay time, {
    ExistingPeriodicWorkPolicy policy = ExistingPeriodicWorkPolicy.replace,
  }) async {
    await Workmanager().registerPeriodicTask(
      _kTaskUniqueName,
      kReminderTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntil(time),
      existingWorkPolicy: policy,
    );
  }

  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(_kTaskUniqueName);
  }

  // Calculates the delay until the next occurrence of [time], always at least
  // 1 minute ahead so WorkManager doesn't fire immediately on re-registration.
  static Duration _delayUntil(TimeOfDay time) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!target.isAfter(now.add(const Duration(minutes: 1)))) {
      target = target.add(const Duration(days: 1));
    }
    return target.difference(now);
  }
}
