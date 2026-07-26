import 'package:adhd_list/features/settings/settings_screen.dart';
import 'package:adhd_list/providers/mood_state.dart';
import 'package:adhd_list/providers/settings_state.dart';
import 'package:adhd_list/providers/task_state.dart';
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
}) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
    expect(find.text('Data'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('updates persisted timer and task defaults', (tester) async {
    final repository = FakeSettingsRepository();
    final settings = SettingsState(repository: repository, autoLoad: false);

    await _pumpSettingsScreen(tester, settings: settings);

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

    await tester.tap(find.text('7 days'));
    await tester.pump();
    expect(settings.defaultDueDateOffsetDays, 7);
    expect(repository.values[SettingsState.defaultDueDateOffsetKey], '7');
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

    await tester.tap(find.byTooltip('Clear task history'));
    await tester.pumpAndSettle();
    expect(find.text('Clear task history?'), findsOneWidget);

    await tester.tap(find.text('Clear tasks'));
    await tester.pumpAndSettle();

    expect(taskRepository.taskRows, isEmpty);
    expect(find.text('Task history cleared'), findsOneWidget);
  });
}
