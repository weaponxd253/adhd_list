import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'timer_notification_service.dart';

class LocalTimerNotificationService implements TimerNotificationService {
  LocalTimerNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _timerCompletionNotificationId = 1001;
  static const _androidChannelId = 'focusflow_timer_completion';
  static const _androidChannelName = 'Timer completions';
  static const _androidChannelDescription =
      'Alerts when a focus or break timer finishes.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> cancelTimerCompletion() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _plugin.cancel(_timerCompletionNotificationId);
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
  Future<void> scheduleTimerCompletion({
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

    await _plugin.cancel(_timerCompletionNotificationId);
    await _plugin.zonedSchedule(
      _timerCompletionNotificationId,
      title,
      body,
      deliveryTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'timer-completion',
    );
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
      category: AndroidNotificationCategory.alarm,
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
