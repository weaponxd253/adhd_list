import 'package:adhd_list/features/dashboard/dashboard_screen.dart';
import 'package:adhd_list/providers/mood_state.dart';
import 'package:adhd_list/providers/task_state.dart';
import 'package:adhd_list/providers/timer_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

class _DashboardHarness {
  _DashboardHarness({
    List<Map<String, dynamic>>? tasks,
    Map<int, List<Map<String, dynamic>>>? subtasks,
    List<Map<String, dynamic>>? moods,
    this.onOpenMood,
    this.onOpenTimer,
  })  : taskRepository = FakeTaskRepository(
          tasks: tasks,
          subtasks: subtasks,
        ),
        moodRepository = FakeMoodRepository(entries: moods),
        timerSessionRepository = FakeTimerSessionRepository(),
        notificationService = FakeTimerNotificationService() {
    taskState = TaskState(repository: taskRepository, autoLoad: false);
    moodState = MoodState(repository: moodRepository, autoLoad: false);
    timerState = TimerState(
      notificationService: notificationService,
      sessionRepository: timerSessionRepository,
    );
  }

  final FakeTaskRepository taskRepository;
  final FakeMoodRepository moodRepository;
  final FakeTimerSessionRepository timerSessionRepository;
  final FakeTimerNotificationService notificationService;
  final VoidCallback? onOpenMood;
  final VoidCallback? onOpenTimer;

  late final TaskState taskState;
  late final MoodState moodState;
  late final TimerState timerState;

  void dispose() {
    taskState.dispose();
    moodState.dispose();
    timerState.dispose();
  }
}

Future<_DashboardHarness> _pumpDashboard(
  WidgetTester tester, {
  List<Map<String, dynamic>>? tasks,
  Map<int, List<Map<String, dynamic>>>? subtasks,
  List<Map<String, dynamic>>? moods,
  VoidCallback? onOpenMood,
  VoidCallback? onOpenTimer,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = const Size(430, 930);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final harness = _DashboardHarness(
    tasks: tasks,
    subtasks: subtasks,
    moods: moods,
    onOpenMood: onOpenMood,
    onOpenTimer: onOpenTimer,
  );
  addTearDown(harness.dispose);

  await harness.taskState.loadTasks();
  await harness.moodState.load();

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: harness.taskState),
          ChangeNotifierProvider.value(value: harness.moodState),
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
  final today = DateTime(2026, 8, 3);

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
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('dashboard quick start begins a five minute focus session',
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
    expect(openedTimer, isTrue);
    harness.timerState.stopTimer();
  });

  testWidgets('dashboard tiny start begins a two minute focus session',
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
    expect(openedTimer, isTrue);
    expect(find.text('2 minute tiny focus started'), findsOneWidget);
    harness.timerState.stopTimer();
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
