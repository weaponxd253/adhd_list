import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/home/home_screen.dart';
import 'providers/mood_state.dart';
import 'providers/settings_state.dart';
import 'providers/task_state.dart';
import 'providers/timer_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskState()),
        ChangeNotifierProvider(create: (_) => TimerState()),
        ChangeNotifierProvider(create: (_) => MoodState()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
      ],
      child: Consumer<SettingsState>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'FocusFlow',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
