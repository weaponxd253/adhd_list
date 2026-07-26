import 'package:adhd_list/providers/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('SettingsState', () {
    test('defaults to light and loads a saved dark theme', () async {
      final light = SettingsState(
        repository: FakeSettingsRepository(),
        autoLoad: false,
      );
      await light.loadTheme();
      expect(light.themeMode, ThemeMode.light);

      final dark = SettingsState(
        repository: FakeSettingsRepository(value: 'dark'),
        autoLoad: false,
      );
      await dark.loadTheme();
      expect(dark.themeMode, ThemeMode.dark);
    });

    test('persists theme changes before publishing state', () async {
      final repository = FakeSettingsRepository();
      final state = SettingsState(repository: repository, autoLoad: false);

      await state.toggleTheme();
      expect(repository.values[SettingsState.themeModeKey], 'dark');
      expect(state.themeMode, ThemeMode.dark);
    });

    test('loads persisted timer and task defaults', () async {
      final repository = FakeSettingsRepository(
        values: {
          SettingsState.focusDurationKey: '45',
          SettingsState.shortBreakDurationKey: '8',
          SettingsState.longBreakDurationKey: '20',
          SettingsState.defaultDueDateOffsetKey: '7',
          SettingsState.timerNotificationsEnabledKey: 'true',
        },
      );
      final state = SettingsState(repository: repository, autoLoad: false);

      await state.load();

      expect(state.focusDuration, 45);
      expect(state.shortBreakDuration, 8);
      expect(state.longBreakDuration, 20);
      expect(state.defaultDueDateOffsetDays, 7);
      expect(state.timerNotificationsEnabled, isTrue);
    });

    test('persists timer durations together', () async {
      final repository = FakeSettingsRepository();
      final state = SettingsState(repository: repository, autoLoad: false);

      await state.setTimerDurations(
        focus: 50,
        shortBreak: 10,
        longBreak: 25,
      );

      expect(repository.values[SettingsState.focusDurationKey], '50');
      expect(repository.values[SettingsState.shortBreakDurationKey], '10');
      expect(repository.values[SettingsState.longBreakDurationKey], '25');
      expect(state.focusDuration, 50);
      expect(state.shortBreakDuration, 10);
      expect(state.longBreakDuration, 25);
    });

    test('persists supported default due date offsets', () async {
      final repository = FakeSettingsRepository();
      final state = SettingsState(repository: repository, autoLoad: false);

      await state.setDefaultDueDateOffsetDays(7);

      expect(repository.values[SettingsState.defaultDueDateOffsetKey], '7');
      expect(state.defaultDueDateOffsetDays, 7);
    });

    test('persists timer notification preference', () async {
      final repository = FakeSettingsRepository();
      final state = SettingsState(repository: repository, autoLoad: false);

      await state.setTimerNotificationsEnabled(true);

      expect(
        repository.values[SettingsState.timerNotificationsEnabledKey],
        'true',
      );
      expect(state.timerNotificationsEnabled, isTrue);
    });

    test('applies timer presets through duration persistence', () async {
      final repository = FakeSettingsRepository();
      final state = SettingsState(repository: repository, autoLoad: false);

      await state.applyTimerPreset(SettingsState.timerPresets.last);

      expect(state.focusDuration, 50);
      expect(state.shortBreakDuration, 10);
      expect(state.longBreakDuration, 30);
      expect(repository.values[SettingsState.focusDurationKey], '50');
      expect(repository.values[SettingsState.shortBreakDurationKey], '10');
      expect(repository.values[SettingsState.longBreakDurationKey], '30');
    });

    test('failed persistence leaves the visible theme unchanged', () async {
      final repository = FakeSettingsRepository()..failWrites = true;
      final state = SettingsState(repository: repository, autoLoad: false);

      await expectLater(state.toggleTheme(), throwsStateError);
      expect(state.themeMode, ThemeMode.light);
    });
  });
}
