import 'package:adhd_list/features/dashboard/dashboard_screen.dart';
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

final _dashboardTestToday = DateTime(2026, 8, 3);

class _DashboardHarness {
  _DashboardHarness({
    List<Map<String, dynamic>>? tasks,
    Map<int, List<Map<String, dynamic>>>? subtasks,
    List<Map<String, dynamic>>? moods,
    List<Map<String, Object?>>? timerSessions,
    DateTime Function()? now,
    this.onOpenMood,
    this.onOpenTimer,
  })  : taskRepository = FakeTaskRepository(
          tasks: tasks,
          subtasks: subtasks,
        ),
        moodRepository = FakeMoodRepository(entries: moods),
        settingsRepository = FakeSettingsRepository(),
        taskReminderRepository = FakeTaskReminderRepository(),
        timerSessionRepository = FakeTimerSessionRepository(
          sessions: timerSessions,
        ),
        taskReminderNotificationService = FakeTaskReminderNotificationService(),
        notificationService = FakeTimerNotificationService() {
    taskState = TaskState(
      repository: taskRepository,
      now: now,
      autoLoad: false,
    );
    moodState = MoodState(repository: moodRepository, autoLoad: false);
    settingsState = SettingsState(
      repository: settingsRepository,
      autoLoad: false,
    );
    taskReminderState = TaskReminderState(
      repository: taskReminderRepository,
      notificationService: taskReminderNotificationService,
      now: now,
      autoLoad: false,
    );
    timerState = TimerState(
      now: now,
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
  final VoidCallback? onOpenMood;
  final VoidCallback? onOpenTimer;

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

Future<_DashboardHarness> _pumpDashboard(
  WidgetTester tester, {
  List<Map<String, dynamic>>? tasks,
  Map<int, List<Map<String, dynamic>>>? subtasks,
  List<Map<String, dynamic>>? moods,
  List<Map<String, Object?>>? timerSessions,
  DateTime Function()? now,
  VoidCallback? onOpenMood,
  VoidCallback? onOpenTimer,
  bool taskRemindersEnabled = false,
  TaskReminderStyle taskReminderStyle = TaskReminderStyle.gentle,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = const Size(430, 930);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final effectiveNow = now ?? () => _dashboardTestToday;
  final harness = _DashboardHarness(
    tasks: tasks,
    subtasks: subtasks,
    moods: moods,
    timerSessions: timerSessions,
    now: effectiveNow,
    onOpenMood: onOpenMood,
    onOpenTimer: onOpenTimer,
  );
  addTearDown(harness.dispose);

  await harness.taskState.loadTasks();
  await harness.moodState.load();
  if (timerSessions != null) {
    await harness.timerState.loadSessionHistory();
  }
  if (taskRemindersEnabled) {
    await harness.settingsState.setTaskRemindersEnabled(true);
  }
  await harness.settingsState.setTaskReminderStyle(taskReminderStyle);
  harness.taskReminderState.updateSettings(
    remindersEnabled: harness.settingsState.taskRemindersEnabled,
    defaultStyle: harness.settingsState.taskReminderStyle,
  );

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: harness.taskState),
          ChangeNotifierProvider.value(value: harness.moodState),
          ChangeNotifierProvider.value(value: harness.settingsState),
          ChangeNotifierProvider.value(value: harness.taskReminderState),
          ChangeNotifierProvider.value(value: harness.timerState),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DashboardScreen(
            onOpenMood: onOpenMood,
            onOpenTimer: onOpenTimer,
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  return harness;
}

void main() {
  final today = _dashboardTestToday;

  testWidgets('now card prioritizes the first task and next excludes it',
      (tester) async {
    await _pumpDashboard(
      tester,
      tasks: [
        taskRow(id: 1, title: 'Do homework', dueDate: today),
        taskRow(
          id: 2,
          title: 'Pack backpack',
          dueDate: today.add(const Duration(days: 1)),
        ),
      ],
      subtasks: {
        1: [
          subtaskRow(id: 11, taskId: 1, title: 'Open notes'),
          subtaskRow(id: 12, taskId: 1, title: 'Write answer'),
        ],
      },
    );

    expect(find.text('Do homework'), findsOneWidget);
    expect(find.text('Open notes'), findsOneWidget);
    expect(find.text('Pack backpack'), findsOneWidget);
    expect(find.text('0/2 steps'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(
        find.text('One focus block can get it moving again.'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('dashboard quick start shows an active focus state',
      (tester) async {
    var openedTimer = false;
    final harness = await _pumpDashboard(
      tester,
      tasks: [taskRow(id: 1, title: 'Do homework', dueDate: today)],
      onOpenTimer: () => openedTimer = true,
    );

    await tester.tap(find.byKey(const Key('dashboard-start-5')));
    await tester.pump();

    expect(harness.timerState.isTimerRunning, isTrue);
    expect(harness.timerState.timerDisplay, '05:00');
    expect(harness.timerState.activeTaskId, 1);
    expect(harness.timerState.activeTargetType, TimerState.targetTypeTask);
    expect(harness.timerState.activeTargetTitle, 'Do homework');
    expect(openedTimer, isFalse);
    expect(find.byKey(const Key('dashboard-active-focus')), findsOneWidget);
    expect(find.text('In progress · 05:00 left'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-start-5')), findsNothing);
    harness.timerState.stopTimer();
  });

  testWidgets('dashboard tiny start shows an active focus state',
      (tester) async {
    var openedTimer = false;
    final harness = await _pumpDashboard(
      tester,
      tasks: [taskRow(id: 1, title: 'Do homework', dueDate: today)],
      onOpenTimer: () => openedTimer = true,
    );

    await tester.tap(find.byKey(const Key('dashboard-start-tiny')));
    await tester.pump();

    expect(harness.timerState.isTimerRunning, isTrue);
    expect(harness.timerState.timerDisplay, '02:00');
    expect(harness.timerState.activeTaskId, 1);
    expect(harness.timerState.activeTargetType, TimerState.targetTypeTask);
    expect(harness.timerState.activeTargetTitle, 'Do homework');
    expect(openedTimer, isFalse);
    expect(find.text('In progress · 02:00 left'), findsOneWidget);
    harness.timerState.stopTimer();
  });

  testWidgets('dashboard active focus replaces start actions', (tester) async {
    final harness = await _pumpDashboard(
      tester,
      tasks: [
        taskRow(id: 1, title: 'First task', dueDate: today),
        taskRow(id: 2, title: 'Second task', dueDate: today),
      ],
    );

    await tester.tap(find.byKey(const Key('dashboard-start-tiny')));
    await tester.pump();
    final firstTaskId = harness.timerState.activeTaskId;
    final firstTaskTitle = harness.timerState.activeTargetTitle;

    expect(harness.timerState.timerDisplay, '02:00');
    expect(harness.timerState.activeTaskId, firstTaskId);
    expect(harness.timerState.activeTargetTitle, firstTaskTitle);
    expect(find.byKey(const Key('dashboard-start-5')), findsNothing);
    expect(find.byKey(const Key('dashboard-end-active-focus')), findsOneWidget);
    harness.timerState.stopTimer();
  });

  testWidgets('dashboard can end active task focus early', (tester) async {
    final startedAt = DateTime(2026, 8, 3, 9);
    var now = startedAt;
    final harness = await _pumpDashboard(
      tester,
      now: () => now,
      tasks: [taskRow(id: 1, title: 'Do homework', dueDate: today)],
    );

    await tester.tap(find.byKey(const Key('dashboard-start-5')));
    await tester.pump();
    now = startedAt.add(const Duration(seconds: 90));
    harness.timerState.syncWithClock();
    await tester.pump();

    expect(find.text('In progress · 03:30 left'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboard-end-active-focus')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(harness.timerState.isTimerRunning, isFalse);
    expect(harness.timerState.currentMode, 'Short Break');
    expect(
        harness.timerSessionRepository.sessionRows.single['duration_seconds'],
        90);
    expect(find.text('Did that get finished?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('linked-completion-leave-open')));
    await tester.pump();

    expect(
      harness.timerSessionRepository.sessionRows.single['outcome'],
      TimerState.outcomeLeftOpen,
    );
  });

  testWidgets('dashboard tiny step adds a subtask', (tester) async {
    final harness = await _pumpDashboard(
      tester,
      tasks: [taskRow(id: 1, title: 'Do homework', dueDate: today)],
    );

    await tester.tap(find.byKey(const Key('dashboard-tiny-step')));
    await tester.pump();

    expect(harness.taskRepository.subtaskRows[1], hasLength(1));
    expect(
      harness.taskRepository.subtaskRows[1]!.single['title'],
      contains('Do homework'),
    );
  });

  testWidgets('dashboard tiny step does not add duplicates', (tester) async {
    final harness = await _pumpDashboard(
      tester,
      tasks: [taskRow(id: 1, title: 'Do homework', dueDate: today)],
    );

    await tester.tap(find.byKey(const Key('dashboard-tiny-step')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dashboard-tiny-step')));
    await tester.pump();

    expect(harness.taskRepository.subtaskRows[1], hasLength(1));
    expect(find.text('Tiny step is already there'), findsOneWidget);
  });

  testWidgets('dashboard stuck button opens support sheet', (tester) async {
    await _pumpDashboard(
      tester,
      tasks: [taskRow(id: 1, title: 'Do homework', dueDate: today)],
    );

    await tester.tap(find.byKey(const Key('dashboard-stuck')));
    await tester.pumpAndSettle();

    expect(find.text('I am stuck'), findsOneWidget);
    expect(find.text("What's the blocker?"), findsOneWidget);
    expect(find.byKey(const ValueKey('friction-distracted')), findsOneWidget);
  });

  testWidgets('dashboard resurfaces a waiting task with gentle actions',
      (tester) async {
    var openedTimer = false;
    final harness = await _pumpDashboard(
      tester,
      now: () => today,
      onOpenTimer: () => openedTimer = true,
      tasks: [
        taskRow(
          id: 1,
          title: 'Old paperwork',
          dueDate: today.subtract(const Duration(days: 3)),
        ),
        taskRow(
          id: 2,
          title: 'Fresh task',
          dueDate: today.add(const Duration(days: 1)),
        ),
      ],
    );

    await tester.scrollUntilVisible(find.text('This has been waiting'), 320);
    await tester.pump();

    expect(find.text('Old paperwork'), findsOneWidget);
    expect(
      find.text('Still worth doing. Want a 2-minute start?'),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('waiting-nudge-style')),
        matching: find.text('Tiny step'),
      ),
    );
    await tester.pump();
    expect(
      find.textContaining('Only do this next tiny step'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('waiting-shrink-task')));
    await tester.pump();
    expect(harness.taskRepository.subtaskRows[1], hasLength(1));

    await tester.tap(find.byKey(const Key('waiting-start-tiny')));
    await tester.pump();
    expect(harness.timerState.timerDisplay, '02:00');
    expect(openedTimer, isTrue);
    harness.timerState.stopTimer();

    await tester.tap(find.byKey(const Key('waiting-move-later')));
    await tester.pump();
    final dueDate = DateTime.parse(
      harness.taskRepository.taskRows.first['due_date'] as String,
    );
    expect(dueDate, DateTime(today.year, today.month, today.day + 7));
  });

  testWidgets('dashboard suggests resuming a task left open after focus',
      (tester) async {
    var openedTimer = false;
    final harness = await _pumpDashboard(
      tester,
      now: () => today,
      onOpenTimer: () => openedTimer = true,
      tasks: [
        taskRow(id: 1, title: 'Do homework', dueDate: today),
        taskRow(
          id: 2,
          title: 'Essay',
          dueDate: today.add(const Duration(days: 1)),
        ),
      ],
      subtasks: {
        2: [
          subtaskRow(id: 20, taskId: 2, title: 'Draft outline'),
        ],
      },
      timerSessions: [
        {
          'id': 1,
          'mode': 'Focus',
          'started_at': DateTime(2026, 8, 3, 8).toIso8601String(),
          'ended_at': DateTime(2026, 8, 3, 8, 5).toIso8601String(),
          'duration_seconds': 300,
          'completed': 1,
          'task_id': 2,
          'subtask_id': 20,
          'target_type': TimerState.targetTypeSubtask,
          'target_title_snapshot': 'Draft outline',
          'outcome': TimerState.outcomeLeftOpen,
        },
      ],
    );

    expect(find.text('Still open'), findsOneWidget);
    expect(find.text('Draft outline · Essay'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboard-resume-focus')));
    await tester.pump();

    expect(harness.timerState.isTimerRunning, isTrue);
    expect(harness.timerState.timerDisplay, '05:00');
    expect(harness.timerState.activeTaskId, 2);
    expect(harness.timerState.activeSubtaskId, 20);
    expect(harness.timerState.activeTargetType, TimerState.targetTypeSubtask);
    expect(harness.timerState.activeTargetTitle, 'Draft outline');
    expect(openedTimer, isTrue);
    harness.timerState.stopTimer();
  });

  testWidgets('dashboard waiting card can schedule and cancel a reminder',
      (tester) async {
    final harness = await _pumpDashboard(
      tester,
      now: () => today,
      taskRemindersEnabled: true,
      tasks: [
        taskRow(
          id: 1,
          title: 'Old paperwork',
          dueDate: today.subtract(const Duration(days: 3)),
        ),
      ],
    );

    await tester.scrollUntilVisible(find.text('This has been waiting'), 320);
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('waiting-nudge-style')),
        matching: find.text('Tiny step'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('waiting-remind-tomorrow')));
    await tester.pump();

    expect(harness.taskReminderNotificationService.permissionRequests, 1);
    expect(
      harness.taskReminderRepository.reminderRows.single['style'],
      'tinyStep',
    );
    expect(find.text('Reminder set for tomorrow'), findsOneWidget);
    expect(find.textContaining('Nudge set'), findsOneWidget);

    await tester.tap(find.byKey(const Key('waiting-cancel-reminder')));
    await tester.pump();

    expect(harness.taskReminderRepository.reminderRows, isEmpty);
    expect(
      harness.taskReminderNotificationService.canceledTaskIds,
      contains(1),
    );
  });

  testWidgets('dashboard adapts now guidance to anxious mood', (tester) async {
    await _pumpDashboard(
      tester,
      tasks: [taskRow(id: 1, title: 'Email professor', dueDate: today)],
      moods: [
        {
          'id': 1,
          'mood': 'Anxious',
          'emoji': ':(',
          'date': today.toIso8601String(),
        },
      ],
    );

    expect(find.text('Do the safest version that counts.'), findsOneWidget);
    expect(
      find.text(
        'Try a 2-minute tiny start and do the safest version that counts.',
      ),
      findsWidgets,
    );
  });

  testWidgets('dashboard capacity selector lowers the daily plan',
      (tester) async {
    await _pumpDashboard(
      tester,
      tasks: [taskRow(id: 1, title: 'Do homework', dueDate: today)],
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('daily-capacity-selector')),
      320,
    );
    await tester.pump();

    expect(find.text('How much capacity do you have?'), findsOneWidget);
    expect(find.text('One task plus one focus session is the plan.'),
        findsOneWidget);

    await tester.tap(find.text('Low'));
    await tester.pump();

    expect(find.text('One tiny task is enough today. Setup counts.'),
        findsOneWidget);
    expect(
      find.text(
        'Recovery mode: 1 tiny task, 1 mood check-in, optional 2-minute focus.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('dashboard shows a gentle daily review prompt', (tester) async {
    await _pumpDashboard(
      tester,
      tasks: [taskRow(id: 1, title: 'Do homework', dueDate: today)],
    );

    await tester.scrollUntilVisible(find.text('What counted today?'), 320);
    await tester.pump();

    expect(find.text('What counted today?'), findsOneWidget);
    expect(find.text('You showed up. That counted.'), findsOneWidget);
    expect(find.text('What helped?'), findsOneWidget);
    expect(find.text('Tomorrow start with Do homework.'), findsOneWidget);
  });

  testWidgets('dashboard can choose tomorrow starter', (tester) async {
    final harness = await _pumpDashboard(
      tester,
      tasks: [
        taskRow(id: 1, title: 'First task', dueDate: today),
        taskRow(
          id: 2,
          title: 'Second task',
          dueDate: today.add(const Duration(days: 1)),
        ),
      ],
    );

    await tester.scrollUntilVisible(
        find.byKey(const Key('tomorrow-starter-menu')), 320);
    await tester.pump();
    await tester.tap(find.byKey(const Key('tomorrow-starter-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second task').last);
    await tester.pumpAndSettle();

    expect(harness.taskState.tomorrowStarterTask?.title, 'Second task');
    expect(find.text('Tomorrow start with Second task.'), findsOneWidget);
  });

  testWidgets('mood card is tappable', (tester) async {
    var openedMood = false;
    await _pumpDashboard(
      tester,
      onOpenMood: () => openedMood = true,
      moods: [
        {
          'id': 1,
          'mood': 'Calm',
          'emoji': ':)',
          'date': today.toIso8601String(),
        },
      ],
    );

    await tester.tap(find.byKey(const Key('dashboard-mood-card')));
    await tester.pump();

    expect(openedMood, isTrue);
  });

  testWidgets('dashboard supports large text without overflow', (tester) async {
    await _pumpDashboard(
      tester,
      textScaler: const TextScaler.linear(2),
      tasks: [taskRow(id: 1, title: 'Do homework', dueDate: today)],
    );

    expect(tester.takeException(), isNull);
  });
}
