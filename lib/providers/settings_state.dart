import 'dart:async';

import 'package:flutter/material.dart';

import '../database/settings_database.dart';
import '../repositories/repositories.dart';

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

  static const minTimerMinutes = 1;
  static const maxTimerMinutes = 180;
  static const defaultFocusDuration = 25;
  static const defaultShortBreakDuration = 5;
  static const defaultLongBreakDuration = 15;
  static const defaultDueDateOffset = 30;
  static const dueDateOffsetOptions = [1, 7, 30];

  final SettingsRepository _repository;
  ThemeMode _themeMode = ThemeMode.light;
  int _focusDuration = defaultFocusDuration;
  int _shortBreakDuration = defaultShortBreakDuration;
  int _longBreakDuration = defaultLongBreakDuration;
  int _defaultDueDateOffsetDays = defaultDueDateOffset;

  ThemeMode get themeMode => _themeMode;
  int get focusDuration => _focusDuration;
  int get shortBreakDuration => _shortBreakDuration;
  int get longBreakDuration => _longBreakDuration;
  int get defaultDueDateOffsetDays => _defaultDueDateOffsetDays;

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

  Future<void> setDefaultDueDateOffsetDays(int days) async {
    if (!dueDateOffsetOptions.contains(days)) {
      throw ArgumentError.value(days, 'days', 'Unsupported due date offset');
    }
    if (days == _defaultDueDateOffsetDays) return;

    await _repository.write(defaultDueDateOffsetKey, '$days');
    _defaultDueDateOffsetDays = days;
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
