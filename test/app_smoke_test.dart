import 'package:adhd_list/features/home/home_screen.dart';
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

class _SmokeHarness {
  _SmokeHarness()
      : taskRepository = FakeTaskRepository(),
        moodRepository = FakeMoodRepository(),
        settingsRepository = FakeSettingsRepository(),
        taskReminderRepository = FakeTaskReminderRepository(),
        timerSessionRepository = FakeTimerSessionRepository(),
        taskReminderNotificationService = FakeTaskReminderNotificationService(),
        notificationService = FakeTimerNotificationService() {
    taskState = TaskState(
      repository: taskRepository,
      autoLoad: false,
    );
    moodState = MoodState(
      repository: moodRepository,
      autoLoad: false,
    );
    settingsState = SettingsState(
      repository: settingsRepository,
      autoLoad: false,
    );
    taskReminderState = TaskReminderState(
      repository: taskReminderRepository,
      notificationService: taskReminderNotificationService,
      autoLoad: false,
    );
    timerState = TimerState(
      notificationService: notificationService,
      sessionRepository: timerSessionRepository,
    );
  }

  final FakeTaskRepository taskRepository;
  final FakeMoodRepository moodRepository;
  final FakeSettingsRepository settingsRepository;
  final FakeTaskReminderRepository taskReminderRepository;
  final FakeTimerSessionRepository timerSessionRepository;
  final FakeTaskReminderNotificationService taskReminderNotificationService;
  final FakeTimerNotificationService notificationService;

  late final TaskState taskState;
  late final MoodState moodState;
  late final SettingsState settingsState;
  late final TaskReminderState taskReminderState;
  late final TimerState timerState;

  void dispose() {
    taskState.dispose();
    moodState.dispose();
    settingsState.dispose();
    taskReminderState.dispose();
    timerState.dispose();
  }
}

Future<_SmokeHarness> _pumpSmokeApp(
  WidgetTester tester, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(430, 930);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final harness = _SmokeHarness();
  addTearDown(harness.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: harness.taskState),
        ChangeNotifierProvider.value(value: harness.moodState),
        ChangeNotifierProvider.value(value: harness.settingsState),
        ChangeNotifierProvider.value(value: harness.taskReminderState),
        ChangeNotifierProvider.value(value: harness.timerState),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pump();

  return harness;
}

Future<void> _pumpAppFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _pumpRoutePop(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('critical app flow stays wired together', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final harness = await _pumpSmokeApp(tester);

      expect(find.text('FocusFlow'), findsOneWidget);

      await tester.tap(find.byKey(const Key('navigation-tasks')));
      await _pumpAppFrame(tester);
      await tester.enterText(
        find.byKey(const Key('task-name-field')),
        'Smoke task',
      );
      await tester.tap(find.byKey(const Key('add-task-button')));
      await _pumpAppFrame(tester);

      expect(find.text('Smoke task'), findsOneWidget);
      expect(harness.taskRepository.taskRows, hasLength(1));

      await tester.tap(find.byTooltip('Expand task'));
      await _pumpAppFrame(tester);
      await tester.enterText(
        find.byKey(const ValueKey('add-subtask-field-100')),
        'Prep workspace',
      );
      await tester.tap(find.byKey(const ValueKey('add-subtask-button-100')));
      await _pumpAppFrame(tester);

      expect(find.text('Prep workspace'), findsOneWidget);
      expect(harness.taskRepository.subtaskRows[100], hasLength(1));

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('subtask-200')),
          matching: find.byType(Checkbox),
        ),
      );
      await _pumpAppFrame(tester);
      expect(
          harness.taskRepository.subtaskRows[100]!.single['is_completed'], 1);

      await tester.tap(find.byKey(const Key('navigation-timer')));
      await _pumpAppFrame(tester);
      expect(find.text('Ready to start'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Start timer'));
      await tester.pump();
      expect(harness.timerState.isTimerRunning, isTrue);
      expect(find.text('Session in progress'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Pause timer'));
      await tester.pump();
      expect(harness.timerState.isTimerRunning, isFalse);

      await tester.tap(find.byTooltip('Timer history'));
      await _pumpAppFrame(tester);
      expect(find.text('Timer History'), findsOneWidget);
      await tester.pageBack();
      await _pumpRoutePop(tester);

      await tester.tap(find.byKey(const Key('navigation-mood')));
      await _pumpAppFrame(tester);
      await tester.tap(find.text('Calm'));
      await _pumpAppFrame(tester);
      expect(harness.moodState.selectedMood, 'Calm');
      expect(harness.moodRepository.entries.first['mood'], 'Calm');

      await tester.tap(find.byTooltip('Mood history'));
      await _pumpAppFrame(tester);
      expect(find.text('Mood History'), findsOneWidget);
      expect(find.text('Calm'), findsWidgets);
      await tester.pageBack();
      await _pumpRoutePop(tester);

      await tester.tap(find.byKey(const Key('navigation-home')));
      await _pumpAppFrame(tester);
      await tester.tap(find.byTooltip('Settings'));
      await _pumpAppFrame(tester);
      expect(find.text('Timer notifications'), findsOneWidget);

      await tester.tap(find.byKey(const Key('timer-notifications-toggle')));
      await _pumpAppFrame(tester);
      expect(harness.notificationService.permissionRequests, 1);
      expect(harness.timerState.notificationPermissionGranted, isTrue);
      expect(find.text('Enabled'), findsOneWidget);

      await tester.tap(find.byKey(const Key('timer-notifications-toggle')));
      await _pumpAppFrame(tester);
      expect(harness.settingsState.timerNotificationsEnabled, isFalse);
      expect(harness.timerState.notificationsEnabled, isFalse);
      expect(harness.notificationService.cancelCount, greaterThanOrEqualTo(1));
      expect(find.text('Off'), findsWidgets);

      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('primary destinations render in light and dark without overflow',
      (tester) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await _pumpSmokeApp(tester, theme: theme);

      for (final key in const [
        Key('navigation-home'),
        Key('navigation-tasks'),
        Key('navigation-timer'),
        Key('navigation-mood'),
      ]) {
        await tester.tap(find.byKey(key));
        await _pumpAppFrame(tester);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
