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
      expect(repository.value, 'dark');
      expect(state.themeMode, ThemeMode.dark);
    });

    test('failed persistence leaves the visible theme unchanged', () async {
      final repository = FakeSettingsRepository()..failWrites = true;
      final state = SettingsState(repository: repository, autoLoad: false);

      await expectLater(state.toggleTheme(), throwsStateError);
      expect(state.themeMode, ThemeMode.light);
    });
  });
}
