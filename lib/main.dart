import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'features/home/home_screen.dart';
import 'providers/mood_state.dart';
import 'providers/settings_state.dart';
import 'providers/task_state.dart';
import 'providers/timer_state.dart';
import 'services/local_timer_notification_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskState()),
        ChangeNotifierProvider(create: (_) => MoodState()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProxyProvider<SettingsState, TimerState>(
          create: (_) => TimerState(
            autoLoadHistory: true,
            notificationService: LocalTimerNotificationService(),
          ),
          update: (_, settings, timerState) {
            final state = timerState ??
                TimerState(
                  autoLoadHistory: true,
                  notificationService: LocalTimerNotificationService(),
                );
            state.updateSettings(
              focus: settings.focusDuration,
              shortBreak: settings.shortBreakDuration,
              longBreak: settings.longBreakDuration,
              notificationsEnabled: settings.timerNotificationsEnabled,
            );
            return state;
          },
        ),
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
            builder: (context, child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.systemOverlayStyle(
                  Theme.of(context).brightness,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
