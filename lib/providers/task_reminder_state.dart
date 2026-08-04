import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../database/task_reminder_database.dart';
import '../models/task.dart';
import '../models/task_reminder.dart';
import '../repositories/repositories.dart';
import '../services/task_reminder_notification_service.dart';

class TaskReminderState extends ChangeNotifier {
  TaskReminderState({
    TaskReminderRepository? repository,
    TaskReminderNotificationService? notificationService,
    DateTime Function()? now,
    bool autoLoad = true,
  })  : _repository = repository ?? TaskReminderDatabase(),
        _notificationService =
            notificationService ?? const NoopTaskReminderNotificationService(),
        _now = now ?? DateTime.now {
    if (autoLoad) unawaited(loadReminders());
  }

  final TaskReminderRepository _repository;
  final TaskReminderNotificationService _notificationService;
  final DateTime Function() _now;
  final Map<int, TaskReminder> _reminders = {};

  bool _remindersEnabled = false;
  bool _notificationPermissionGranted = false;
  bool _isLoading = false;
  bool _disposed = false;
  String? _lastError;
  TaskReminderStyle _defaultStyle = TaskReminderStyle.gentle;

  UnmodifiableMapView<int, TaskReminder> get reminders =>
      UnmodifiableMapView(_reminders);
  bool get remindersEnabled => _remindersEnabled;
  bool get notificationPermissionGranted => _notificationPermissionGranted;
  bool get notificationPermissionNeeded =>
      _remindersEnabled && !_notificationPermissionGranted;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  TaskReminderStyle get defaultStyle => _defaultStyle;
  int get activeReminderCount => _reminders.length;

  TaskReminder? reminderFor(int taskId) => _reminders[taskId];
  bool hasReminderFor(int taskId) => _reminders.containsKey(taskId);

  Future<void> loadReminders() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final rows = await _repository.fetchTaskReminders();
      if (_disposed) return;
      _reminders
        ..clear()
        ..addEntries(
          rows
              .map(TaskReminder.fromMap)
              .where((reminder) => reminder.enabled)
              .map((reminder) => MapEntry(reminder.taskId, reminder)),
        );
    } catch (_) {
      if (_disposed) return;
      _lastError = 'Could not load task reminders.';
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void updateSettings({
    required bool remindersEnabled,
    required TaskReminderStyle defaultStyle,
  }) {
    final enabledChanged = _remindersEnabled != remindersEnabled;
    final styleChanged = _defaultStyle != defaultStyle;
    if (!enabledChanged && !styleChanged) return;

    _remindersEnabled = remindersEnabled;
    _defaultStyle = defaultStyle;
    if (!_remindersEnabled) {
      _notificationPermissionGranted = false;
      unawaited(_cancelAllRemindersQuietly());
    }
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    if (!_remindersEnabled) {
      if (_notificationPermissionGranted) {
        _notificationPermissionGranted = false;
        notifyListeners();
      }
      return false;
    }

    final granted = await _notificationService.requestPermission();
    if (_disposed) return false;
    if (_notificationPermissionGranted != granted) {
      _notificationPermissionGranted = granted;
      notifyListeners();
    }
    return granted;
  }

  Future<bool> remindLater(
    Task task, {
    required String tinyStep,
    TaskReminderStyle? style,
  }) {
    return scheduleReminder(
      task: task,
      tinyStep: tinyStep,
      scheduledAt: _now().add(const Duration(hours: 3)),
      style: style,
    );
  }

  Future<bool> remindTomorrow(
    Task task, {
    required String tinyStep,
    TaskReminderStyle? style,
  }) {
    return scheduleReminder(
      task: task,
      tinyStep: tinyStep,
      scheduledAt: _tomorrowMorning(_now()),
      style: style,
    );
  }

  Future<bool> scheduleReminder({
    required Task task,
    required String tinyStep,
    required DateTime scheduledAt,
    TaskReminderStyle? style,
  }) async {
    if (task.isCompleted) {
      _lastError = 'Completed tasks do not need reminders.';
      notifyListeners();
      return false;
    }

    if (!_remindersEnabled) {
      _lastError = 'Task nudges are off.';
      notifyListeners();
      return false;
    }

    final granted =
        _notificationPermissionGranted || await requestNotificationPermission();
    if (!granted) {
      _lastError = 'Notification permission is needed for task nudges.';
      notifyListeners();
      return false;
    }

    final selectedStyle = style ?? _defaultStyle;
    final reminder = TaskReminder(
      taskId: task.id,
      style: selectedStyle,
      scheduledAt: scheduledAt,
    );

    try {
      await _notificationService.scheduleTaskReminder(
        taskId: task.id,
        when: scheduledAt,
        title: selectedStyle.titleFor(task),
        body: selectedStyle.bodyFor(task, tinyStep),
      );
      await _repository.upsertTaskReminder(
        taskId: task.id,
        style: selectedStyle.id,
        scheduledAt: scheduledAt.toIso8601String(),
        enabled: true,
      );
      if (_disposed) return false;
      _lastError = null;
      _reminders[task.id] = reminder;
      notifyListeners();
      return true;
    } catch (_) {
      await _notificationService.cancelTaskReminder(task.id);
      if (_disposed) return false;
      _lastError = 'Could not schedule that reminder.';
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelReminder(int taskId) async {
    await _notificationService.cancelTaskReminder(taskId);
    await _repository.deleteTaskReminder(taskId);
    if (_disposed) return;
    _reminders.remove(taskId);
    notifyListeners();
  }

  Future<void> cancelAllReminders() async {
    await _notificationService.cancelAllTaskReminders();
    await _repository.clearTaskReminders();
    if (_disposed) return;
    _reminders.clear();
    notifyListeners();
  }

  Future<void> _cancelAllRemindersQuietly() async {
    try {
      await cancelAllReminders();
    } catch (_) {
      if (_disposed) return;
      _lastError = 'Could not clear task reminders.';
      notifyListeners();
    }
  }

  DateTime _tomorrowMorning(DateTime base) {
    final tomorrow =
        DateTime(base.year, base.month, base.day).add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
