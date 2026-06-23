import 'dart:async';

import 'package:flutter/material.dart';

import '../database/settings_database.dart';

class SettingsState extends ChangeNotifier {
  SettingsState() {
    unawaited(_loadTheme());
  }

  final SettingsDatabase _database = SettingsDatabase();
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadTheme() async {
    final value = await _database.read('theme_mode');
    _themeMode = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final next =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _database.write('theme_mode', next.name);
    _themeMode = next;
    notifyListeners();
  }
}
