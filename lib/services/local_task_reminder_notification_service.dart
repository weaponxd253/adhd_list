import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'task_reminder_notification_service.dart';

class LocalTaskReminderNotificationService
    implements TaskReminderNotificationService {
  LocalTaskReminderNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _taskReminderNotificationBaseId = 200000;
  static const _taskReminderNotificationLimit = 100000;
  static const _androidChannelId = 'focusflow_task_reminders';
  static const _androidChannelName = 'Task nudges';
  static const _androidChannelDescription =
      'Optional reminders for tasks you choose to nudge later.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> cancelAllTaskReminders() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (_isTaskReminderNotificationId(request.id)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  @override
  Future<void> cancelTaskReminder(int taskId) async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _plugin.cancel(_notificationIdForTask(taskId));
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await _ensureInitialized();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _requestAndroidPermissions();
      case TargetPlatform.iOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(
                  alert: true,
                  sound: true,
                ) ??
            true;
      case TargetPlatform.macOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    MacOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(
                  alert: true,
                  sound: true,
                ) ??
            true;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return true;
    }
  }

  @override
  Future<void> scheduleTaskReminder({
    required int taskId,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) return;

    await _ensureInitialized();
    final now = timezone.TZDateTime.now(timezone.local);
    final scheduled = timezone.TZDateTime.from(when, timezone.local);
    final deliveryTime = scheduled.isAfter(now)
        ? scheduled
        : now.add(const Duration(seconds: 1));

    final notificationId = _notificationIdForTask(taskId);
    await _plugin.cancel(notificationId);
    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      deliveryTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task-reminder:$taskId',
    );
  }

  int _notificationIdForTask(int taskId) {
    final normalized = taskId % _taskReminderNotificationLimit;
    return _taskReminderNotificationBaseId + normalized;
  }

  bool _isTaskReminderNotificationId(int id) {
    return id >= _taskReminderNotificationBaseId &&
        id < _taskReminderNotificationBaseId + _taskReminderNotificationLimit;
  }

  Future<bool> _requestAndroidPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;

    final notificationsGranted =
        await android.requestNotificationsPermission() ?? true;
    if (!notificationsGranted) return false;

    final exactAlreadyGranted =
        await android.canScheduleExactNotifications() ?? true;
    if (exactAlreadyGranted) return true;

    return await android.requestExactAlarmsPermission() ?? false;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    timezone_data.initializeTimeZones();
    await _plugin.initialize(_initializationSettings);
    _initialized = true;
  }

  static const _initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
    macOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
    linux: LinuxInitializationSettings(defaultActionName: 'Open FocusFlow'),
    windows: WindowsInitializationSettings(
      appName: 'FocusFlow',
      appUserModelId: 'Xavier.FocusFlow',
      guid: 'e969aa0d-67d6-46c3-ae34-a14e9bf1dced',
    ),
  );

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    ),
    windows: WindowsNotificationDetails(
      duration: WindowsNotificationDuration.long,
    ),
  );
}
