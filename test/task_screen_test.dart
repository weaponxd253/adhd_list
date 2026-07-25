import 'package:adhd_list/features/task_breakdown/task_screen.dart';
import 'package:adhd_list/providers/task_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

Future<void> _pumpTaskScreen(
  WidgetTester tester,
  TaskState state,
) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: state,
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

    expect(find.byTooltip('Edit Accessible task'), findsOneWidget);
    expect(find.byTooltip('Delete Accessible task'), findsOneWidget);
    expect(find.byTooltip('Expand task'), findsOneWidget);
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

    await tester.tap(find.byTooltip('Delete Undo task'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Undo task deleted'), findsOneWidget);
    expect(find.text('Undo task'), findsNothing);

    await tester.tap(find.byType(SnackBarAction));
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
        child: ChangeNotifierProvider.value(
          value: state,
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
