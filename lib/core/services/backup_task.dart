import 'package:latitude_tracker/core/services/backup_dispatcher.dart';
import 'package:workmanager/workmanager.dart';

const _kTaskUniqueName = 'daily-drive-backup';

class BackupTask {
  const BackupTask._();

  static Future<void> register() async {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _kTaskUniqueName,
      kBackupTaskName,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.unmetered),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
