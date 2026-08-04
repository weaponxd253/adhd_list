import 'package:adhd_list/features/task_breakdown/task_screen.dart';
import 'package:adhd_list/providers/settings_state.dart';
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
  TimerState? timerState,
}) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(
          value: settings ??
              SettingsState(
                repository: FakeSettingsRepository(),
                autoLoad: false,
              ),
        ),
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
    expect(find.text('Start tiny'), findsOneWidget);
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
    await tester.tap(find.text('Start tiny'));
    await tester.pump();

    expect(timerState.isTimerRunning, isTrue);
    expect(timerState.timerDisplay, '02:00');
    expect(find.text('2 minute tiny focus started'), findsOneWidget);
    timerState.stopTimer();
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
            ChangeNotifierProvider(
              create: (_) => SettingsState(
                repository: FakeSettingsRepository(),
                autoLoad: false,
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
