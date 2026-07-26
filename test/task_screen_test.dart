import 'package:adhd_list/features/task_breakdown/task_screen.dart';
import 'package:adhd_list/providers/settings_state.dart';
import 'package:adhd_list/providers/task_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

Future<void> _pumpTaskScreen(
  WidgetTester tester,
  TaskState state, {
  SettingsState? settings,
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

  testWidgets('separates pending and completed tasks', (tester) async {
    final state = TaskState(
      repository: FakeTaskRepository(
        tasks: [
          taskRow(id: 1, title: 'Pending task', dueDate: today),
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

    expect(find.text('Pending task'), findsOneWidget);
    expect(find.text('Finished task'), findsNothing);

    await tester.tap(find.text('Completed'));
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

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
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
