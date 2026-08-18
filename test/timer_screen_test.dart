import 'package:adhd_list/features/timer/timer_screen.dart';
import 'package:adhd_list/providers/task_state.dart';
import 'package:adhd_list/providers/timer_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

Future<void> _pumpTimerScreen(
  WidgetTester tester,
  TimerState state, {
  TaskState? taskState,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(state.dispose);
  if (taskState != null) addTearDown(taskState.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        if (taskState != null) ChangeNotifierProvider.value(value: taskState),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const TimerScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows timer status and completion feedback', (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final state = TimerState(
      now: () => now,
      sessionRepository: FakeTimerSessionRepository(),
    )..updateDurations(focus: 1, shortBreak: 5, longBreak: 15);
    await _pumpTimerScreen(tester, state);

    expect(find.text('Ready to start'), findsOneWidget);
    expect(find.text('Focus session'), findsOneWidget);

    state.startTimer();
    await tester.pump();
    expect(find.text('Session in progress'), findsOneWidget);

    now = startedAt.add(const Duration(minutes: 1));
    state.syncWithClock();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Short Break ready'), findsOneWidget);
    expect(find.text('That counted.'), findsOneWidget);
    expect(find.text('1m focus counted.'), findsOneWidget);
    expect(find.text('Take break'), findsOneWidget);
    expect(find.text('Focus complete. Short Break ready.'), findsOneWidget);

    final keepGoing = tester.widget<FilledButton>(
      find.byKey(const Key('completion-keep-going')),
    );
    keepGoing.onPressed?.call();
    await tester.pump();

    expect(state.isTimerRunning, isTrue);
    expect(state.timerDisplay, '05:00');
    expect(state.hasActiveTarget, isFalse);
    state.stopTimer();
  });

  testWidgets('shows active task context for linked focus sessions',
      (tester) async {
    final state = TimerState(
      sessionRepository: FakeTimerSessionRepository(),
    );
    await _pumpTimerScreen(tester, state);

    state.startTargetFocus(
      minutes: 10,
      targetType: TimerState.targetTypeTask,
      taskId: 7,
      title: 'Write report',
    );
    await tester.pump();

    expect(find.text('Working on'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Focus session'), findsNothing);
    state.stopTimer();
  });

  testWidgets('shows current task details for linked focus sessions',
      (tester) async {
    final taskRepository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Project task', dueDate: DateTime(2026))],
      subtasks: {
        1: [subtaskRow(id: 2, taskId: 1, title: 'Write outline')],
      },
    );
    final taskState = TaskState(repository: taskRepository, autoLoad: false);
    await taskState.loadTasks();
    final timerState = TimerState(
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
            'target_title_snapshot': 'Write outline',
          },
        ],
      ),
    );
    await timerState.loadSessionHistory();
    await _pumpTimerScreen(tester, timerState, taskState: taskState);

    timerState.startTargetFocus(
      minutes: 10,
      targetType: TimerState.targetTypeSubtask,
      taskId: 1,
      subtaskId: 2,
      title: 'Write outline',
    );
    await tester.pump();

    expect(find.text('Current task'), findsOneWidget);
    expect(find.text('Project task'), findsOneWidget);
    expect(find.text('0/1 steps - 12m focus'), findsOneWidget);
    expect(find.text('Working on: Write outline'), findsOneWidget);

    await tester.tap(find.byKey(const Key('timer-current-mark-done')));
    await tester.pump();

    expect(taskRepository.subtaskRows[1]!.single['is_completed'], 1);
    expect(find.text('Step marked done'), findsOneWidget);
    timerState.stopTimer();
  });

  testWidgets('reconciles completed sessions when the app resumes',
      (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final state = TimerState(
      now: () => now,
      sessionRepository: FakeTimerSessionRepository(),
    )..updateDurations(focus: 1, shortBreak: 5, longBreak: 15);
    await _pumpTimerScreen(tester, state);

    state.startTimer();
    await tester.pump();

    now = startedAt.add(const Duration(seconds: 75));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Short Break ready'), findsOneWidget);
    expect(find.text('That counted.'), findsOneWidget);
    expect(find.text('Focus complete. Short Break ready.'), findsOneWidget);
  });

  testWidgets('keep going preserves linked task context', (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final state = TimerState(
      now: () => now,
      sessionRepository: FakeTimerSessionRepository(),
    );
    await _pumpTimerScreen(tester, state);

    state.startTargetFocus(
      minutes: 1,
      targetType: TimerState.targetTypeTask,
      taskId: 7,
      title: 'Write report',
    );
    await tester.pump();

    now = startedAt.add(const Duration(minutes: 1));
    state.syncWithClock();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mark task done'), findsOneWidget);
    expect(find.text('1m counted toward Write report.'), findsOneWidget);

    final keepGoing = tester.widget<FilledButton>(
      find.byKey(const Key('completion-keep-going')),
    );
    keepGoing.onPressed?.call();
    await tester.pump();

    expect(state.isTimerRunning, isTrue);
    expect(state.timerDisplay, '05:00');
    expect(state.activeTaskId, 7);
    expect(state.activeTargetType, TimerState.targetTypeTask);
    expect(state.activeTargetTitle, 'Write report');
    state.stopTimer();
  });

  testWidgets('completion sheet can mark a linked subtask done',
      (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final taskRepository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Project task', dueDate: startedAt)],
      subtasks: {
        1: [subtaskRow(id: 2, taskId: 1, title: 'Write outline')],
      },
    );
    final taskState = TaskState(
      repository: taskRepository,
      autoLoad: false,
    );
    await taskState.loadTasks();
    final timerState = TimerState(
      now: () => now,
      sessionRepository: FakeTimerSessionRepository(),
    );
    await _pumpTimerScreen(tester, timerState, taskState: taskState);

    timerState.startTargetFocus(
      minutes: 1,
      targetType: TimerState.targetTypeSubtask,
      taskId: 1,
      subtaskId: 2,
      title: 'Write outline',
    );
    await tester.pump();

    now = startedAt.add(const Duration(minutes: 1));
    timerState.syncWithClock();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mark step done'), findsOneWidget);
    expect(find.text('1m counted toward Write outline.'), findsOneWidget);

    final markDone = tester.widget<OutlinedButton>(
      find.byKey(const Key('completion-mark-target-done')),
    );
    markDone.onPressed?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(taskRepository.subtaskRows[1]!.single['is_completed'], 1);
    expect(find.text('Step marked done'), findsOneWidget);
  });

  testWidgets('skip confirms before discarding a running session',
      (tester) async {
    final state = TimerState(
      sessionRepository: FakeTimerSessionRepository(),
    );
    await _pumpTimerScreen(tester, state);

    state.startTimer();
    await tester.pump();

    await tester.tap(find.byTooltip('Skip to next mode'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Skip this session?'), findsOneWidget);
    expect(find.text('Time from this session will not be counted.'),
        findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(state.isTimerRunning, isTrue);

    await tester.tap(find.byTooltip('Skip to next mode'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(state.isTimerRunning, isFalse);
    expect(state.currentMode, 'Short Break');
  });
}
