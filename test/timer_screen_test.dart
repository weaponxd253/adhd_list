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

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        if (taskState != null) ChangeNotifierProvider.value(value: taskState),
        ChangeNotifierProvider.value(value: state),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const TimerScreen(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpPromptIn(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _pumpPromptOut(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
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
    expect(find.text('Want to keep going or stop here?'), findsOneWidget);
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

  testWidgets('linked task completion prompt can mark task complete',
      (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final taskRepository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Write report', dueDate: startedAt)],
    );
    final taskState = TaskState(repository: taskRepository, autoLoad: false);
    await taskState.loadTasks();
    final timerRepository = FakeTimerSessionRepository();
    final state = TimerState(
      now: () => now,
      sessionRepository: timerRepository,
    );
    await _pumpTimerScreen(tester, state, taskState: taskState);

    state.startTargetFocus(
      minutes: 1,
      targetType: TimerState.targetTypeTask,
      taskId: 1,
      title: 'Write report',
    );
    await tester.pump();
    now = startedAt.add(const Duration(minutes: 1));
    state.syncWithClock();
    await _pumpPromptIn(tester);

    expect(find.text('Did that get finished?'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Mark task complete'), findsOneWidget);

    await tester.tap(find.byKey(const Key('linked-completion-mark-complete')));
    await _pumpPromptOut(tester);

    expect(taskState.tasks.single.isCompleted, isTrue);
    expect(timerRepository.sessionRows.single['outcome'], 'task_completed');
    expect(state.pendingCompletionTarget, isNull);
  });

  testWidgets('linked subtask completion prompt can mark step complete',
      (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final taskRepository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Write report', dueDate: startedAt)],
      subtasks: {
        1: [subtaskRow(id: 2, taskId: 1, title: 'Find one source')],
      },
    );
    final taskState = TaskState(repository: taskRepository, autoLoad: false);
    await taskState.loadTasks();
    final timerRepository = FakeTimerSessionRepository();
    final state = TimerState(
      now: () => now,
      sessionRepository: timerRepository,
    );
    await _pumpTimerScreen(tester, state, taskState: taskState);

    state.startTargetFocus(
      minutes: 1,
      targetType: TimerState.targetTypeSubtask,
      taskId: 1,
      subtaskId: 2,
      title: 'Find one source',
    );
    await tester.pump();
    now = startedAt.add(const Duration(minutes: 1));
    state.syncWithClock();
    await _pumpPromptIn(tester);

    expect(find.text('Find one source'), findsOneWidget);
    expect(find.text('Mark step complete'), findsOneWidget);

    await tester.tap(find.byKey(const Key('linked-completion-mark-complete')));
    await _pumpPromptOut(tester);

    expect(taskState.tasks.single.subtasks.single.isCompleted, isTrue);
    expect(timerRepository.sessionRows.single['outcome'], 'subtask_completed');
    expect(state.pendingCompletionTarget, isNull);
  });

  testWidgets('linked completion can continue or leave open', (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final taskRepository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Write report', dueDate: startedAt)],
    );
    final taskState = TaskState(repository: taskRepository, autoLoad: false);
    await taskState.loadTasks();
    final timerRepository = FakeTimerSessionRepository();
    final state = TimerState(
      now: () => now,
      sessionRepository: timerRepository,
    );
    await _pumpTimerScreen(tester, state, taskState: taskState);

    state.startTargetFocus(
      minutes: 1,
      targetType: TimerState.targetTypeTask,
      taskId: 1,
      title: 'Write report',
    );
    await tester.pump();
    now = startedAt.add(const Duration(minutes: 1));
    state.syncWithClock();
    await _pumpPromptIn(tester);

    await tester.tap(find.byKey(const Key('linked-completion-add-five')));
    await _pumpPromptOut(tester);

    expect(timerRepository.sessionRows.single['outcome'], 'continued');
    expect(state.isTimerRunning, isTrue);
    expect(state.timerDisplay, '05:00');
    expect(state.activeTaskId, 1);
    expect(state.activeTargetTitle, 'Write report');

    now = startedAt.add(const Duration(minutes: 6));
    state.syncWithClock();
    await _pumpPromptIn(tester);

    await tester.tap(find.byKey(const Key('linked-completion-leave-open')));
    await _pumpPromptOut(tester);

    expect(taskState.tasks.single.isCompleted, isFalse);
    expect(timerRepository.sessionRows.first['outcome'], 'left_open');
    expect(state.pendingCompletionTarget, isNull);
  });

  testWidgets('linked completion can leave a break ready', (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final taskRepository = FakeTaskRepository(
      tasks: [taskRow(id: 1, title: 'Write report', dueDate: startedAt)],
    );
    final taskState = TaskState(repository: taskRepository, autoLoad: false);
    await taskState.loadTasks();
    final timerRepository = FakeTimerSessionRepository();
    final state = TimerState(
      now: () => now,
      sessionRepository: timerRepository,
    );
    await _pumpTimerScreen(tester, state, taskState: taskState);

    state.startTargetFocus(
      minutes: 1,
      targetType: TimerState.targetTypeTask,
      taskId: 1,
      title: 'Write report',
    );
    await tester.pump();
    now = startedAt.add(const Duration(minutes: 1));
    state.syncWithClock();
    await _pumpPromptIn(tester);

    await tester.tap(find.byKey(const Key('linked-completion-take-break')));
    await _pumpPromptOut(tester);

    expect(state.currentMode, 'Short Break');
    expect(state.isTimerRunning, isFalse);
    expect(timerRepository.sessionRows.single['outcome'], 'break_ready');
    expect(taskState.tasks.single.isCompleted, isFalse);
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
}
