import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:suraksha_women_safety_app/features/sos/distress/distress_task_handler.dart';

class DistressForegroundController {
  DistressForegroundController._();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'suraksha_distress_monitor',
        channelName: 'Distress monitor',
        channelDescription:
            'Listens for screams and distress phrases to help trigger SOS safely.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1500),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  static Future<bool> start({
    required String sensitivity,
    required bool testMode,
  }) async {
    await ensureInitialized();

    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Suraksha distress monitor active',
        notificationText: testMode
            ? 'Test mode — no SOS will be sent.'
            : 'Listening for screams and help phrases offline.',
      );
      FlutterForegroundTask.sendDataToTask({
        'cmd': 'config',
        'sensitivity': sensitivity,
        'testMode': testMode,
      });
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Suraksha distress monitor active',
      notificationText: testMode
          ? 'Test mode — no SOS will be sent.'
          : 'Listening offline for screams and distress phrases.',
      callback: startDistressTaskCallback,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  static void addDataListener(void Function(Object data) listener) {
    FlutterForegroundTask.addTaskDataCallback(listener);
  }

  static void removeDataListener(void Function(Object data) listener) {
    FlutterForegroundTask.removeTaskDataCallback(listener);
  }
}
