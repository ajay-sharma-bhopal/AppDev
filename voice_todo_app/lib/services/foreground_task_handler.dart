// Native implementation (Android/iOS only).
// Imported via conditional import in main.dart — never imported on web.
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class _TippidiTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_TippidiTaskHandler());
}

void initForegroundCommunicationPort() {}

void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'tippidi_foreground',
      channelName: 'Tippidi Listener',
      channelDescription: 'Keeps Tippidi listening in the background',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );
}

Future<void> startForegroundListening() async {
  if (await FlutterForegroundTask.isRunningService) return;
  await FlutterForegroundTask.startService(
    serviceId: 256,
    notificationTitle: 'Tippidi is listening',
    notificationText: 'Say "Tippidi" followed by your task',
    callback: startCallback,
  );
}

Future<void> stopForegroundListening() async {
  await FlutterForegroundTask.stopService();
}
