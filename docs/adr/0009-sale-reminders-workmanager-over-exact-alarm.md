# Sale reminders use WorkManager, not exact alarm scheduling

`flutter_local_notifications` supports `zonedSchedule()` with `AndroidScheduleMode.exactAllowWhileIdle`, which fires at precisely the configured time. We chose WorkManager instead (the same periodic-task mechanism used by DriveBackup) because exact scheduling requires the `SCHEDULE_EXACT_ALARM` permission on Android 12+. Google Play flags this permission for scrutiny on apps that are not clocks, timers, or calendar-style apps — a daily sales nudge does not qualify, and approval is not guaranteed.

WorkManager may deliver the notification up to ~15 minutes late due to battery-optimisation batching. For a gentle daily reminder this is acceptable.
