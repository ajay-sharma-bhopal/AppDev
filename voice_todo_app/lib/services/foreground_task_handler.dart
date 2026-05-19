// Native implementation (Android/iOS only).
// Imported via conditional import in main.dart — never imported on web.
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class _TippidiTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_TippidiTaskHandler());
}

void initForegroundCommunicationPort() {
  FlutterForegroundTask.initCommunicationPort();
}

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
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 5000,
      isOnceEvent: false,
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );
}

Future<void> startForegroundListening() async {
  if (await FlutterForegroundTask.isRunningService) return;
  await FlutterForegroundTask.startService(
    notificationTitle: 'Tippidi is listening',
    notificationText: 'Say "Tippidi" followed by your task',
    callback: startCallback,
  );
}

Future<void> stopForegroundListening() async {
  await FlutterForegroundTask.stopService();
}
