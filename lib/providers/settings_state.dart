import 'dart:async';

import 'package:flutter/material.dart';

import '../database/settings_database.dart';
import '../models/task_reminder.dart';
import '../repositories/repositories.dart';

@immutable
class TimerPreset {
  const TimerPreset({
    required this.label,
    required this.focus,
    required this.shortBreak,
    required this.longBreak,
  });

  final String label;
  final int focus;
  final int shortBreak;
  final int longBreak;
}

class SettingsState extends ChangeNotifier {
  SettingsState({
    SettingsRepository? repository,
    bool autoLoad = true,
  }) : _repository = repository ?? SettingsDatabase() {
    if (autoLoad) unawaited(load());
  }

  static const themeModeKey = 'theme_mode';
  static const focusDurationKey = 'focus_duration_minutes';
  static const shortBreakDurationKey = 'short_break_duration_minutes';
  static const longBreakDurationKey = 'long_break_duration_minutes';
  static const defaultDueDateOffsetKey = 'default_due_date_offset_days';
  static const timerNotificationsEnabledKey = 'timer_notifications_enabled';
  static const taskRemindersEnabledKey = 'task_reminders_enabled';
  static const taskReminderStyleKey = 'task_reminder_style';

  static const minTimerMinutes = 1;
  static const maxTimerMinutes = 180;
  static const defaultFocusDuration = 25;
  static const defaultShortBreakDuration = 5;
  static const defaultLongBreakDuration = 15;
  static const defaultDueDateOffset = 30;
  static const defaultTimerNotificationsEnabled = false;
  static const defaultTaskRemindersEnabled = false;
  static const defaultTaskReminderStyle = TaskReminderStyle.gentle;
  static const dueDateOffsetOptions = [1, 7, 30];
  static const timerPresets = [
    TimerPreset(
      label: 'Classic',
      focus: 25,
      shortBreak: 5,
      longBreak: 15,
    ),
    TimerPreset(
      label: 'Gentle',
      focus: 15,
      shortBreak: 5,
      longBreak: 10,
    ),
    TimerPreset(
      label: 'Deep Work',
      focus: 50,
      shortBreak: 10,
      longBreak: 30,
    ),
  ];

  final SettingsRepository _repository;
  ThemeMode _themeMode = ThemeMode.light;
  int _focusDuration = defaultFocusDuration;
  int _shortBreakDuration = defaultShortBreakDuration;
  int _longBreakDuration = defaultLongBreakDuration;
  int _defaultDueDateOffsetDays = defaultDueDateOffset;
  bool _timerNotificationsEnabled = defaultTimerNotificationsEnabled;
  bool _taskRemindersEnabled = defaultTaskRemindersEnabled;
  TaskReminderStyle _taskReminderStyle = defaultTaskReminderStyle;

  ThemeMode get themeMode => _themeMode;
  int get focusDuration => _focusDuration;
  int get shortBreakDuration => _shortBreakDuration;
  int get longBreakDuration => _longBreakDuration;
  int get defaultDueDateOffsetDays => _defaultDueDateOffsetDays;
  bool get timerNotificationsEnabled => _timerNotificationsEnabled;
  bool get taskRemindersEnabled => _taskRemindersEnabled;
  TaskReminderStyle get taskReminderStyle => _taskReminderStyle;

  Future<void> load() async {
    _themeMode = _themeModeFromValue(await _repository.read(themeModeKey));
    _focusDuration = _intFromValue(
      await _repository.read(focusDurationKey),
      defaultFocusDuration,
      min: minTimerMinutes,
      max: maxTimerMinutes,
    );
    _shortBreakDuration = _intFromValue(
      await _repository.read(shortBreakDurationKey),
      defaultShortBreakDuration,
      min: minTimerMinutes,
      max: maxTimerMinutes,
    );
    _longBreakDuration = _intFromValue(
      await _repository.read(longBreakDurationKey),
      defaultLongBreakDuration,
      min: minTimerMinutes,
      max: maxTimerMinutes,
    );
    final dueDateOffset = _intFromValue(
      await _repository.read(defaultDueDateOffsetKey),
      defaultDueDateOffset,
      min: 1,
      max: 365,
    );
    _defaultDueDateOffsetDays = dueDateOffsetOptions.contains(dueDateOffset)
        ? dueDateOffset
        : defaultDueDateOffset;
    _timerNotificationsEnabled = _boolFromValue(
      await _repository.read(timerNotificationsEnabledKey),
      defaultTimerNotificationsEnabled,
    );
    _taskRemindersEnabled = _boolFromValue(
      await _repository.read(taskRemindersEnabledKey),
      defaultTaskRemindersEnabled,
    );
    _taskReminderStyle = TaskReminderStyle.fromId(
      await _repository.read(taskReminderStyleKey),
    );
    notifyListeners();
  }

  Future<void> loadTheme() => load();

  Future<void> toggleTheme() async {
    final next =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(next);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    await _repository.write(themeModeKey, mode.name);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setTimerDurations({
    required int focus,
    required int shortBreak,
    required int longBreak,
  }) async {
    _validateTimerDuration(focus);
    _validateTimerDuration(shortBreak);
    _validateTimerDuration(longBreak);

    await _repository.write(focusDurationKey, '$focus');
    await _repository.write(shortBreakDurationKey, '$shortBreak');
    await _repository.write(longBreakDurationKey, '$longBreak');

    _focusDuration = focus;
    _shortBreakDuration = shortBreak;
    _longBreakDuration = longBreak;
    notifyListeners();
  }

  Future<void> applyTimerPreset(TimerPreset preset) {
    return setTimerDurations(
      focus: preset.focus,
      shortBreak: preset.shortBreak,
      longBreak: preset.longBreak,
    );
  }

  Future<void> setDefaultDueDateOffsetDays(int days) async {
    if (!dueDateOffsetOptions.contains(days)) {
      throw ArgumentError.value(days, 'days', 'Unsupported due date offset');
    }
    if (days == _defaultDueDateOffsetDays) return;

    await _repository.write(defaultDueDateOffsetKey, '$days');
    _defaultDueDateOffsetDays = days;
    notifyListeners();
  }

  Future<void> setTimerNotificationsEnabled(bool enabled) async {
    if (enabled == _timerNotificationsEnabled) return;

    await _repository.write(timerNotificationsEnabledKey, '$enabled');
    _timerNotificationsEnabled = enabled;
    notifyListeners();
  }

  Future<void> setTaskRemindersEnabled(bool enabled) async {
    if (enabled == _taskRemindersEnabled) return;

    await _repository.write(taskRemindersEnabledKey, '$enabled');
    _taskRemindersEnabled = enabled;
    notifyListeners();
  }

  Future<void> setTaskReminderStyle(TaskReminderStyle style) async {
    if (style == _taskReminderStyle) return;

    await _repository.write(taskReminderStyleKey, style.id);
    _taskReminderStyle = style;
    notifyListeners();
  }

  ThemeMode _themeModeFromValue(String? value) {
    return value == ThemeMode.dark.name ? ThemeMode.dark : ThemeMode.light;
  }

  int _intFromValue(
    String? value,
    int fallback, {
    required int min,
    required int max,
  }) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < min || parsed > max) return fallback;
    return parsed;
  }

  bool _boolFromValue(String? value, bool fallback) {
    if (value == null) return fallback;
    return value.toLowerCase() == 'true';
  }

  void _validateTimerDuration(int value) {
    if (value < minTimerMinutes || value > maxTimerMinutes) {
      throw ArgumentError.value(
        value,
        'value',
        'Timer duration must be between $minTimerMinutes and $maxTimerMinutes',
      );
    }
  }
}
