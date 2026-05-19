import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static final ReminderService _instance = ReminderService._();
  factory ReminderService() => _instance;
  ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'tippidi_reminders';
  static const _channelName = 'Task Reminders';

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedule a notification for [taskId]. frequency: 'once' | 'daily' | 'weekly'
  Future<void> scheduleReminder(
    String taskId,
    String taskTitle,
    DateTime reminderAt,
    String frequency,
  ) async {
    if (kIsWeb || !_initialized || frequency == 'none') return;

    final id = _notificationId(taskId);
    final scheduled = tz.TZDateTime.from(reminderAt.toUtc(), tz.UTC);

    DateTimeComponents? repeat;
    if (frequency == 'daily') repeat = DateTimeComponents.time;
    if (frequency == 'weekly') repeat = DateTimeComponents.dayOfWeekAndTime;

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      'Tippidi Reminder',
      taskTitle,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeat,
    );
  }

  Future<void> cancelReminder(String taskId) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(_notificationId(taskId));
  }

  int _notificationId(String taskId) =>
      taskId.hashCode.abs() % 2147483647;
}
