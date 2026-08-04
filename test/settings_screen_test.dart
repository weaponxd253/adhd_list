import 'package:adhd_list/features/settings/settings_screen.dart';
import 'package:adhd_list/models/task_reminder.dart';
import 'package:adhd_list/providers/mood_state.dart';
import 'package:adhd_list/providers/settings_state.dart';
import 'package:adhd_list/providers/task_reminder_state.dart';
import 'package:adhd_list/providers/task_state.dart';
import 'package:adhd_list/providers/timer_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

Future<void> _pumpSettingsScreen(
  WidgetTester tester, {
  required SettingsState settings,
  TaskState? taskState,
  MoodState? moodState,
  TaskReminderState? taskReminderState,
  TimerState? timerState,
}) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final resolvedTimerState = timerState ??
      TimerState(
        notificationService: FakeTimerNotificationService(),
        sessionRepository: FakeTimerSessionRepository(),
      );
  addTearDown(resolvedTimerState.dispose);
  final resolvedTaskReminderState = taskReminderState ??
      TaskReminderState(
        repository: FakeTaskReminderRepository(),
        notificationService: FakeTaskReminderNotificationService(),
        autoLoad: false,
      );
  addTearDown(resolvedTaskReminderState.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(
          value: taskState ??
              TaskState(
                repository: FakeTaskRepository(),
                autoLoad: false,
              ),
        ),
        ChangeNotifierProvider.value(
          value: moodState ??
              MoodState(
                repository: FakeMoodRepository(),
                autoLoad: false,
              ),
        ),
        ChangeNotifierProvider.value(value: resolvedTaskReminderState),
        ChangeNotifierProvider.value(value: resolvedTimerState),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders settings sections', (tester) async {
    final settings = SettingsState(
      repository: FakeSettingsRepository(),
      autoLoad: false,
    );

    await _pumpSettingsScreen(tester, settings: settings);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Data'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Data'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('About'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('updates persisted timer and task defaults', (tester) async {
    final repository = FakeSettingsRepository();
    final settings = SettingsState(repository: repository, autoLoad: false);
    final notificationService = FakeTimerNotificationService();
    final taskReminderNotificationService =
        FakeTaskReminderNotificationService();
    final taskReminderState = TaskReminderState(
      repository: FakeTaskReminderRepository(),
      notificationService: taskReminderNotificationService,
      autoLoad: false,
    );
    final timerState = TimerState(
      notificationService: notificationService,
      sessionRepository: FakeTimerSessionRepository(),
    );

    await _pumpSettingsScreen(
      tester,
      settings: settings,
      taskReminderState: taskReminderState,
      timerState: timerState,
    );

    await tester.tap(find.byKey(const Key('increase-focus-duration')));
    await tester.pump();
    expect(settings.focusDuration, 26);
    expect(repository.values[SettingsState.focusDurationKey], '26');

    await tester.tap(find.byKey(const Key('timer-preset-deep-work')));
    await tester.pump();
    expect(settings.focusDuration, 50);
    expect(settings.shortBreakDuration, 10);
    expect(settings.longBreakDuration, 30);
    expect(repository.values[SettingsState.focusDurationKey], '50');
    expect(repository.values[SettingsState.shortBreakDurationKey], '10');
    expect(repository.values[SettingsState.longBreakDurationKey], '30');

    await tester.tap(find.byKey(const Key('timer-notifications-toggle')));
    await tester.pump();
    expect(settings.timerNotificationsEnabled, isTrue);
    expect(notificationService.permissionRequests, 1);
    expect(timerState.notificationPermissionGranted, isTrue);
    expect(find.text('Enabled'), findsOneWidget);
    expect(
      repository.values[SettingsState.timerNotificationsEnabledKey],
      'true',
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('task-reminders-toggle')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('task-reminders-toggle')));
    await tester.pump();
    expect(settings.taskRemindersEnabled, isTrue);
    expect(taskReminderNotificationService.permissionRequests, 1);
    expect(taskReminderState.notificationPermissionGranted, isTrue);
    expect(
      repository.values[SettingsState.taskRemindersEnabledKey],
      'true',
    );

    await tester.tap(find.text('Direct'));
    await tester.pump();
    expect(settings.taskReminderStyle, TaskReminderStyle.direct);
    expect(repository.values[SettingsState.taskReminderStyleKey], 'direct');

    await tester.tap(find.text('7 days'));
    await tester.pump();
    expect(settings.defaultDueDateOffsetDays, 7);
    expect(repository.values[SettingsState.defaultDueDateOffsetKey], '7');
  });

  testWidgets('turning notifications off cancels pending timer alerts',
      (tester) async {
    final repository = FakeSettingsRepository();
    final settings = SettingsState(repository: repository, autoLoad: false);
    await settings.setTimerNotificationsEnabled(true);

    final notificationService = FakeTimerNotificationService();
    final timerState = TimerState(
      notificationService: notificationService,
      sessionRepository: FakeTimerSessionRepository(),
    );
    timerState.updateSettings(
      focus: settings.focusDuration,
      shortBreak: settings.shortBreakDuration,
      longBreak: settings.longBreakDuration,
      notificationsEnabled: true,
    );
    timerState.startTimer();

    await _pumpSettingsScreen(
      tester,
      settings: settings,
      timerState: timerState,
    );
    await tester.pumpAndSettle();

    expect(notificationService.scheduled, hasLength(1));
    expect(find.text('Enabled'), findsOneWidget);

    await tester.tap(find.byKey(const Key('timer-notifications-toggle')));
    await tester.pumpAndSettle();

    expect(settings.timerNotificationsEnabled, isFalse);
    expect(timerState.notificationsEnabled, isFalse);
    expect(notificationService.cancelCount, greaterThanOrEqualTo(1));
    expect(find.text('Off'), findsWidgets);

    timerState.resetTimer();
    await tester.pump();
  });

  testWidgets('confirms before clearing task history', (tester) async {
    final settings = SettingsState(
      repository: FakeSettingsRepository(),
      autoLoad: false,
    );
    final taskRepository = FakeTaskRepository(
      tasks: [
        taskRow(
          id: 1,
          title: 'Clear me',
          dueDate: DateTime(2026, 6, 23),
        ),
      ],
    );
    final taskState = TaskState(
      repository: taskRepository,
      autoLoad: false,
    );
    await taskState.loadTasks();

    await _pumpSettingsScreen(
      tester,
      settings: settings,
      taskState: taskState,
    );

    await tester.scrollUntilVisible(
      find.byTooltip('Clear task history'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Clear task history'));
    await tester.pumpAndSettle();
    expect(find.text('Clear task history?'), findsOneWidget);

    await tester.tap(find.text('Clear tasks'));
    await tester.pumpAndSettle();

    expect(taskRepository.taskRows, isEmpty);
    expect(find.text('Task history cleared'), findsOneWidget);
  });
}
