import 'dart:async';

import 'package:flutter/material.dart';

import '../database/settings_database.dart';
import '../repositories/repositories.dart';

class SettingsState extends ChangeNotifier {
  SettingsState({
    SettingsRepository? repository,
    bool autoLoad = true,
  }) : _repository = repository ?? SettingsDatabase() {
    if (autoLoad) unawaited(loadTheme());
  }

  final SettingsRepository _repository;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    final value = await _repository.read('theme_mode');
    _themeMode = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final next =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _repository.write('theme_mode', next.name);
    _themeMode = next;
    notifyListeners();
  }
}
