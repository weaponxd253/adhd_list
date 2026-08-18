import 'package:adhd_list/features/task_breakdown/task_screen.dart';
import 'package:adhd_list/models/task_reminder.dart';
import 'package:adhd_list/providers/settings_state.dart';
import 'package:adhd_list/providers/task_reminder_state.dart';
import 'package:adhd_list/providers/task_state.dart';
import 'package:adhd_list/providers/timer_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

Future<void> _pumpTaskScreen(
  WidgetTester tester,
  TaskState state, {
  SettingsState? settings,
  TaskReminderState? taskReminderState,
  TimerState? timerState,
}) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final resolvedSettings = settings ??
      SettingsState(
        repository: FakeSettingsRepository(),
        autoLoad: false,
      );
  final resolvedTaskReminderState = taskReminderState ??
      TaskReminderState(
        repository: FakeTaskReminderRepository(),
        notificationService: FakeTaskReminderNotificationService(),
        autoLoad: false,
      );
  resolvedTaskReminderState.updateSettings(
    remindersEnabled: resolvedSettings.taskRemindersEnabled,
    defaultStyle: resolvedSettings.taskReminderStyle,
  );
  addTearDown(resolvedTaskReminderState.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: resolvedSettings),
        ChangeNotifierProvider.value(value: resolvedTaskReminderState),
        ChangeNotifierProvider.value(
          value: timerState ??
              TimerState(
                notificationService: FakeTimerNotificationService(),
                sessionRepository: FakeTimerSessionRepository(),
              ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const TaskScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  final today = DateTime(2026, 6, 23);

  testWidgets('validates blank task names', (tester) async {
    final state = TaskState(
      repository: FakeTaskRepository(),
      autoLoad: false,
    );
    await _pumpTaskScreen(tester, state);

    await tester.tap(find.byKey(const Key('add-task-button')));
    await tester.pump();

    expect(find.text('Enter a task name'), findsOneWidget);
  });

  testWidgets('shows a retry state when tasks fail to load', (tester) async {
    final repository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Recovered task', dueDate: today)],
    )..failReads = true;
    final state = TaskState(
      repository: repository,
      autoLoad: false,
    );

    await state.loadTasks();
    await _pumpTaskScreen(tester, state);

    expect(find.text('Tasks could not load'), findsOneWidget);
    expect(find.byKey(const Key('retry-load-tasks')), findsOneWidget);

    repository.failReads = false;
    await tester.tap(find.byKey(const Key('retry-load-tasks')));
    await tester.pumpAndSettle();

    expect(find.text('Recovered task'), findsOneWidget);
    expect(find.text('Tasks could not load'), findsNothing);
  });

  testWidgets('uses the configured default due date when no date is selected',
      (tester) async {
    final repository = FakeTaskRepository();
    final taskState = TaskState(
      repository: repository,
      autoLoad: false,
    );
    final settings = SettingsState(
      repository: FakeSettingsRepository(),
      autoLoad: false,
    );
    await settings.setDefaultDueDateOffsetDays(7);
    await _pumpTaskScreen(tester, taskState, settings: settings);

    final beforeSubmit = DateUtils.dateOnly(DateTime.now());
    await tester.enterText(find.byKey(const Key('task-name-field')), 'Plan');
    await tester.tap(find.byKey(const Key('add-task-button')));
    await tester.pumpAndSettle();

    final dueDate =
        DateTime.parse(repository.taskRows.single['due_date'] as String);
    final dueDay = DateUtils.dateOnly(dueDate);

    expect(dueDay.difference(beforeSubmit).inDays, 7);
  });

  testWidgets('groups pending tasks and keeps done collapsed', (tester) async {
    final state = TaskState(
      repository: FakeTaskRepository(
        tasks: [
          taskRow(id: 1, title: 'Now task', dueDate: today),
          taskRow(
            id: 3,
            title: 'Next task',
            dueDate: today.add(const Duration(days: 1)),
          ),
          taskRow(
            id: 4,
            title: 'Second next task',
            dueDate: today.add(const Duration(days: 4)),
          ),
          taskRow(
            id: 5,
            title: 'Later task',
            dueDate: today.add(const Duration(days: 5)),
          ),
          taskRow(
            id: 6,
            title: 'Another later task',
            dueDate: today.add(const Duration(days: 6)),
          ),
          taskRow(
            id: 2,
            title: 'Finished task',
            dueDate: today,
            completed: true,
            completedAt: today,
          ),
        ],
      ),
      autoLoad: false,
    );
    await state.loadTasks();
    await _pumpTaskScreen(tester, state);

    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Now task'), findsOneWidget);
    expect(find.text('Next task'), findsOneWidget);
    expect(find.text('Second next task'), findsOneWidget);
    expect(find.text('Later task'), findsNothing);
    expect(find.text('Finished task'), findsNothing);

    await tester.tap(find.text('Later'));
    await tester.pump();
    expect(find.text('Later task'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(find.text('Finished task'), findsOneWidget);
  });

  testWidgets('task actions expose useful tooltips', (tester) async {
    final state = TaskState(
      repository: FakeTaskRepository(
        tasks: [taskRow(id: 1, title: 'Accessible task', dueDate: today)],
      ),
      autoLoad: false,
    );
    await state.loadTasks();
    await _pumpTaskScreen(tester, state);

    expect(find.byTooltip('Task actions for Accessible task'), findsOneWidget);
    expect(find.byTooltip('Expand task'), findsOneWidget);

    await tester.tap(find.byTooltip('Task actions for Accessible task'));
    await tester.pumpAndSettle();

    expect(find.text("I'm stuck"), findsOneWidget);
    expect(find.text('Start 2 min'), findsOneWidget);
    expect(find.text('Remind later'), findsOneWidget);
    expect(find.text('Remind tomorrow'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('task actions can start a tiny focus session', (tester) async {
    final state = TaskState(
      repository: FakeTaskRepository(
        tasks: [taskRow(id: 1, title: 'Tiny start task', dueDate: today)],
      ),
      autoLoad: false,
    );
    final timerState = TimerState(
      notificationService: FakeTimerNotificationService(),
      sessionRepository: FakeTimerSessionRepository(),
    );
    addTearDown(timerState.dispose);
    await state.loadTasks();
    await _pumpTaskScreen(tester, state, timerState: timerState);

    await tester.tap(find.byTooltip('Task actions for Tiny start task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start 2 min'));
    await tester.pump();

    expect(timerState.isTimerRunning, isTrue);
    expect(timerState.timerDisplay, '02:00');
    expect(timerState.activeTaskId, 1);
    expect(timerState.activeTargetType, TimerState.targetTypeTask);
    expect(timerState.activeTargetTitle, 'Tiny start task');
    expect(find.text('2 minute focus started'), findsOneWidget);
    timerState.stopTimer();
  });

  testWidgets('subtasks can store an estimate and start a linked timer',
      (tester) async {
    final repository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Project task', dueDate: today)],
    );
    final state = TaskState(
      repository: repository,
      autoLoad: false,
    );
    final timerState = TimerState(
      notificationService: FakeTimerNotificationService(),
      sessionRepository: FakeTimerSessionRepository(),
    );
    addTearDown(timerState.dispose);
    await state.loadTasks();
    await _pumpTaskScreen(tester, state, timerState: timerState);

    await tester.tap(find.byTooltip('Expand task'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('subtask-estimate-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 min'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('add-subtask-field-1')),
      'Write outline',
    );
    await tester.tap(find.byKey(const ValueKey('add-subtask-button-1')));
    await tester.pump();

    expect(repository.subtaskRows[1]!.single['estimated_minutes'], 10);
    expect(find.text('10m planned'), findsOneWidget);
    expect(find.byTooltip('Step actions for Write outline'), findsOneWidget);

    await tester.tap(find.byTooltip('Start timer for Write outline'));
    await tester.pump();

    expect(timerState.isTimerRunning, isTrue);
    expect(timerState.timerDisplay, '10:00');
    expect(timerState.activeTaskId, 1);
    expect(timerState.activeSubtaskId, 200);
    expect(timerState.activeTargetType, TimerState.targetTypeSubtask);
    expect(timerState.activeTargetTitle, 'Write outline');
    expect(find.text('10 minute focus started'), findsOneWidget);
    timerState.stopTimer();
  });

<<<<<<< HEAD
  testWidgets('task cards show logged focus time for tasks and subtasks',
      (tester) async {
    final repository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Timed task', dueDate: today)],
      subtasks: {
        1: [
          subtaskRow(
            id: 2,
            taskId: 1,
            title: 'Timed step',
            estimatedMinutes: 10,
=======
  testWidgets('expanded task shows focus memory from linked sessions',
      (tester) async {
    final timerRepository = FakeTimerSessionRepository(
      sessions: [
        {
          'id': 1,
          'mode': 'Focus',
          'started_at': DateTime(2026, 6, 23, 9).toIso8601String(),
          'ended_at': DateTime(2026, 6, 23, 9, 5).toIso8601String(),
          'duration_seconds': 300,
          'completed': 1,
          'task_id': 1,
          'subtask_id': 200,
          'target_type': TimerState.targetTypeSubtask,
          'target_title_snapshot': 'Write outline',
          'outcome': TimerState.outcomeLeftOpen,
        },
      ],
    );
    final repository = FakeTaskRepository(
      tasks: [
        taskRow(
          id: 1,
          title: 'Project task',
          dueDate: today,
          estimatedMinutes: 10,
        ),
      ],
      subtasks: {
        1: [
          subtaskRow(
            id: 200,
            taskId: 1,
            title: 'Write outline',
            estimatedMinutes: 5,
>>>>>>> 116293643c717f05e5b4aafac370a2efdd93a2e1
          ),
        ],
      },
    );
    final state = TaskState(
      repository: repository,
      autoLoad: false,
    );
    final timerState = TimerState(
<<<<<<< HEAD
      sessionRepository: FakeTimerSessionRepository(
        sessions: [
          {
            'id': 1,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 9).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 9, 12).toIso8601String(),
            'duration_seconds': 720,
            'completed': 1,
            'task_id': 1,
            'subtask_id': 2,
            'target_type': TimerState.targetTypeSubtask,
            'target_title_snapshot': 'Timed step',
          },
        ],
      ),
=======
      notificationService: FakeTimerNotificationService(),
      sessionRepository: timerRepository,
>>>>>>> 116293643c717f05e5b4aafac370a2efdd93a2e1
    );
    addTearDown(timerState.dispose);
    await state.loadTasks();
    await timerState.loadSessionHistory();
    await _pumpTaskScreen(tester, state, timerState: timerState);

<<<<<<< HEAD
    expect(find.text('12m focus'), findsOneWidget);
=======
    expect(find.text('Focused 5m'), findsNothing);
>>>>>>> 116293643c717f05e5b4aafac370a2efdd93a2e1

    await tester.tap(find.byTooltip('Expand task'));
    await tester.pump();

<<<<<<< HEAD
    expect(find.text('10m planned - 12m focused'), findsOneWidget);
  });

  testWidgets('too big badge opens task support', (tester) async {
    final tooBigTask = taskRow(
      id: 1,
      title: 'Large task',
      dueDate: today,
    )..['friction'] = 'tooBig';
    final state = TaskState(
      repository: FakeTaskRepository(tasks: [tooBigTask]),
      autoLoad: false,
    );
    await state.loadTasks();
    await _pumpTaskScreen(tester, state);

    await tester.tap(find.byTooltip('Break down Large task'));
    await tester.pumpAndSettle();

    expect(find.text('I am stuck'), findsOneWidget);
    expect(find.text("What's the blocker?"), findsOneWidget);
=======
    expect(find.text('Focused 5m'), findsWidgets);
    expect(find.text('Estimate 10m'), findsOneWidget);
    expect(find.text('Under estimate'), findsOneWidget);
    expect(find.text('Resume candidate'), findsOneWidget);
  });

  testWidgets('active subtask row can end focus early', (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final timerRepository = FakeTimerSessionRepository();
    final repository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Project task', dueDate: today)],
      subtasks: {
        1: [
          subtaskRow(
            id: 200,
            taskId: 1,
            title: 'Write outline',
            estimatedMinutes: 5,
          ),
        ],
      },
    );
    final state = TaskState(
      repository: repository,
      autoLoad: false,
    );
    final timerState = TimerState(
      now: () => now,
      notificationService: FakeTimerNotificationService(),
      sessionRepository: timerRepository,
    );
    addTearDown(timerState.dispose);
    await state.loadTasks();
    await _pumpTaskScreen(tester, state, timerState: timerState);

    await tester.tap(find.byTooltip('Expand task'));
    await tester.pump();
    await tester.tap(find.byTooltip('Start timer for Write outline'));
    await tester.pump();
    now = startedAt.add(const Duration(seconds: 65));
    timerState.syncWithClock();
    await tester.pump();

    expect(find.byKey(const Key('active-subtask-end-focus')), findsOneWidget);
    expect(find.text('03:55 · End'), findsOneWidget);

    await tester.tap(find.byKey(const Key('active-subtask-end-focus')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(timerRepository.sessionRows.single['duration_seconds'], 65);
    expect(find.text('Did that get finished?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('linked-completion-leave-open')));
    await tester.pump();

    expect(
      timerRepository.sessionRows.single['outcome'],
      TimerState.outcomeLeftOpen,
    );
>>>>>>> 116293643c717f05e5b4aafac370a2efdd93a2e1
  });

  testWidgets('task actions can schedule a reminder', (tester) async {
    final state = TaskState(
      repository: FakeTaskRepository(
        tasks: [taskRow(id: 1, title: 'Reminder task', dueDate: today)],
      ),
      autoLoad: false,
    );
    final settings = SettingsState(
      repository: FakeSettingsRepository(),
      autoLoad: false,
    );
    await settings.setTaskRemindersEnabled(true);
    await settings.setTaskReminderStyle(TaskReminderStyle.direct);
    final reminderRepository = FakeTaskReminderRepository();
    final reminderNotificationService = FakeTaskReminderNotificationService();
    final reminderState = TaskReminderState(
      repository: reminderRepository,
      notificationService: reminderNotificationService,
      now: () => DateTime(2026, 6, 23, 14),
      autoLoad: false,
    );
    await state.loadTasks();
    await _pumpTaskScreen(
      tester,
      state,
      settings: settings,
      taskReminderState: reminderState,
    );

    await tester.tap(find.byTooltip('Task actions for Reminder task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remind tomorrow'));
    await tester.pump();

    expect(reminderNotificationService.permissionRequests, 1);
    expect(reminderNotificationService.scheduled.single['taskId'], 1);
    expect(reminderRepository.reminderRows.single['style'], 'direct');
    expect(find.text('Reminder set for tomorrow'), findsOneWidget);
  });

  testWidgets('editing a task saves without controller disposal errors',
      (tester) async {
    final repository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Original task', dueDate: today)],
    );
    final state = TaskState(
      repository: repository,
      autoLoad: false,
    );
    await state.loadTasks();
    await _pumpTaskScreen(tester, state);

    await tester.tap(find.byTooltip('Task actions for Original task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit task'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Renamed task');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.taskRows.single['title'], 'Renamed task');
    expect(find.text('Renamed task'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'stuck flow saves anxiety support, adds a tiny step, and starts timer',
      (tester) async {
    final repository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Hard task', dueDate: today)],
    );
    final state = TaskState(repository: repository, autoLoad: false);
    final timerState = TimerState(
      notificationService: FakeTimerNotificationService(),
      sessionRepository: FakeTimerSessionRepository(),
    );
    addTearDown(timerState.dispose);
    await state.loadTasks();
    await _pumpTaskScreen(tester, state, timerState: timerState);

    await tester.tap(find.byTooltip('Task actions for Hard task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm stuck"));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('friction-boring')), findsNothing);
    expect(find.byKey(const ValueKey('friction-distracted')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('friction-anxious')));
    await tester.pump();
    expect(repository.taskRows.single['friction'], 'anxious');
    expect(find.text('What would make this 10% easier?'), findsOneWidget);
    expect(
      find.text('Do the version that counts, not the perfect version.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('add-tiny-step')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-tiny-step')));
    await tester.pump();
    expect(repository.subtaskRows[1], hasLength(1));

    await tester.ensureVisible(find.byKey(const Key('start-tiny-focus')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('start-tiny-focus')));
    await tester.pump();
    expect(timerState.isTimerRunning, isTrue);
    expect(timerState.timerDisplay, '02:00');
    expect(timerState.activeTaskId, 1);
    expect(timerState.activeTargetType, TimerState.targetTypeTask);
    expect(timerState.activeTargetTitle, 'Hard task');
    timerState.stopTimer();
  });

  testWidgets('deletion offers undo and restores the task', (tester) async {
    final state = TaskState(
      repository: FakeTaskRepository(
        tasks: [taskRow(id: 1, title: 'Undo task', dueDate: today)],
      ),
      autoLoad: false,
    );
    await state.loadTasks();
    await _pumpTaskScreen(tester, state);

    await tester.tap(find.byTooltip('Task actions for Undo task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Undo task deleted'), findsOneWidget);
    expect(find.text('Undo task'), findsNothing);

    final undoAction =
        tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    undoAction.onPressed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Undo task'), findsOneWidget);
  });

  testWidgets('task screen supports large text without overflow',
      (tester) async {
    final state = TaskState(
      repository: FakeTaskRepository(
        tasks: [taskRow(id: 1, title: 'Large text task', dueDate: today)],
      ),
      autoLoad: false,
    );
    await state.loadTasks();
    final timerState = TimerState(
      notificationService: FakeTimerNotificationService(),
      sessionRepository: FakeTimerSessionRepository(),
    );
    addTearDown(timerState.dispose);
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: state),
            ChangeNotifierProvider.value(value: timerState),
            ChangeNotifierProvider(
              create: (_) => SettingsState(
                repository: FakeSettingsRepository(),
                autoLoad: false,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => TaskReminderState(
                repository: FakeTaskReminderRepository(),
                notificationService: FakeTaskReminderNotificationService(),
                autoLoad: false,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => TimerState(
                notificationService: FakeTimerNotificationService(),
                sessionRepository: FakeTimerSessionRepository(),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const TaskScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
