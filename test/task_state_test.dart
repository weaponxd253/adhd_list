import 'package:adhd_list/providers/task_state.dart';
import 'package:adhd_list/models/task_support.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  final today = DateTime(2026, 6, 23, 12);

  group('TaskState', () {
    test('sorts pending tasks before limiting upcoming tasks', () async {
      final repository = FakeTaskRepository(tasks: [
        taskRow(
            id: 1,
            title: 'Fourth',
            dueDate: today.add(const Duration(days: 4))),
        taskRow(
            id: 2, title: 'First', dueDate: today.add(const Duration(days: 1))),
        taskRow(
            id: 3, title: 'Third', dueDate: today.add(const Duration(days: 3))),
        taskRow(
            id: 4,
            title: 'Second',
            dueDate: today.add(const Duration(days: 2))),
        taskRow(
          id: 5,
          title: 'Completed',
          dueDate: today,
          completed: true,
          completedAt: today,
        ),
      ]);
      final state = TaskState(repository: repository, autoLoad: false);
      await state.loadTasks();

      expect(
        state.upcomingTasks.map((task) => task.title),
        ['First', 'Second', 'Third'],
      );
    });

    test('groups pending tasks into now, next, and later', () async {
      final repository = FakeTaskRepository(tasks: [
        taskRow(
            id: 1,
            title: 'Fourth',
            dueDate: today.add(const Duration(days: 4))),
        taskRow(
            id: 2, title: 'First', dueDate: today.add(const Duration(days: 1))),
        taskRow(
            id: 3, title: 'Third', dueDate: today.add(const Duration(days: 3))),
        taskRow(
            id: 4,
            title: 'Second',
            dueDate: today.add(const Duration(days: 2))),
        taskRow(
            id: 5, title: 'Fifth', dueDate: today.add(const Duration(days: 5))),
        taskRow(
          id: 6,
          title: 'Completed',
          dueDate: today,
          completed: true,
          completedAt: today,
        ),
      ]);
      final state = TaskState(repository: repository, autoLoad: false);
      await state.loadTasks();

      expect(state.nowTask?.title, 'First');
      expect(state.nextTasks.map((task) => task.title), ['Second', 'Third']);
      expect(state.laterTasks.map((task) => task.title), ['Fourth', 'Fifth']);
      expect(state.laterTaskCount, 2);
    });

    test('finds overdue untouched tasks as waiting tasks', () async {
      final repository = FakeTaskRepository(
        tasks: [
          taskRow(
            id: 1,
            title: 'Waiting task',
            dueDate: today.subtract(const Duration(days: 3)),
          ),
          taskRow(
            id: 2,
            title: 'Touched task',
            dueDate: today.subtract(const Duration(days: 4)),
          ),
        ],
        subtasks: {
          2: [
            subtaskRow(
              id: 20,
              taskId: 2,
              title: 'Done step',
              completed: true,
            ),
          ],
        },
      );
      final state = TaskState(
        repository: repository,
        now: () => today,
        autoLoad: false,
      );
      await state.loadTasks();

      expect(state.waitingTask?.title, 'Waiting task');
    });

    test('moves waiting tasks to later', () async {
      final repository = FakeTaskRepository(
        tasks: [
          taskRow(
            id: 1,
            title: 'Waiting task',
            dueDate: today.subtract(const Duration(days: 3)),
          ),
        ],
      );
      final state = TaskState(
        repository: repository,
        now: () => today,
        autoLoad: false,
      );
      await state.loadTasks();

      await state.moveTaskToLater(1);

      final dueDate =
          DateTime.parse(repository.taskRows.single['due_date'] as String);
      expect(dueDate, DateTime(today.year, today.month, today.day + 7));
      expect(state.waitingTask, isNull);
    });

    test('stores and clears a tomorrow starter selection', () async {
      final repository = FakeTaskRepository(
        tasks: [
          taskRow(id: 1, title: 'First task', dueDate: today),
          taskRow(id: 2, title: 'Chosen task', dueDate: today),
        ],
      );
      final state = TaskState(repository: repository, autoLoad: false);
      await state.loadTasks();

      expect(state.tomorrowStarterTask?.title, 'First task');

      state.setTomorrowStarter(2);
      expect(state.selectedTomorrowStarterTask?.title, 'Chosen task');
      expect(state.tomorrowStarterTask?.title, 'Chosen task');

      await state.toggleTaskCompletion(2);
      expect(state.selectedTomorrowStarterTask, isNull);
      expect(state.tomorrowStarterTask?.title, 'First task');
    });

    test('task completion, later moves, and deletion cancel reminders',
        () async {
      final taskRepository = FakeTaskRepository(
        tasks: [
          taskRow(id: 1, title: 'Finish me', dueDate: today),
          taskRow(id: 2, title: 'Move me', dueDate: today),
          taskRow(id: 3, title: 'Delete me', dueDate: today),
        ],
      );
      final reminderRepository = FakeTaskReminderRepository(
        reminders: [
          {
            'task_id': 1,
            'style': 'gentle',
            'scheduled_at': today.toIso8601String(),
            'enabled': 1,
          },
          {
            'task_id': 2,
            'style': 'gentle',
            'scheduled_at': today.toIso8601String(),
            'enabled': 1,
          },
          {
            'task_id': 3,
            'style': 'gentle',
            'scheduled_at': today.toIso8601String(),
            'enabled': 1,
          },
        ],
      );
      final notificationService = FakeTaskReminderNotificationService();
      final state = TaskState(
        repository: taskRepository,
        taskReminderRepository: reminderRepository,
        taskReminderNotificationService: notificationService,
        now: () => today,
        autoLoad: false,
      );
      await state.loadTasks();

      await state.toggleTaskCompletion(1);
      await state.moveTaskToLater(2);
      await state.deleteTask(3);

      expect(notificationService.canceledTaskIds, containsAll([1, 2, 3]));
      expect(reminderRepository.reminderRows, isEmpty);
    });

    test('clearing task history cancels all reminders', () async {
      final reminderRepository = FakeTaskReminderRepository(
        reminders: [
          {
            'task_id': 1,
            'style': 'gentle',
            'scheduled_at': today.toIso8601String(),
            'enabled': 1,
          },
        ],
      );
      final notificationService = FakeTaskReminderNotificationService();
      final state = TaskState(
        repository: FakeTaskRepository(
          tasks: [taskRow(id: 1, title: 'Clear me', dueDate: today)],
        ),
        taskReminderRepository: reminderRepository,
        taskReminderNotificationService: notificationService,
        autoLoad: false,
      );
      await state.loadTasks();

      await state.clearTaskHistory();

      expect(notificationService.cancelAllCount, 1);
      expect(reminderRepository.reminderRows, isEmpty);
    });

    test('calculates task, subtask, points, and streak statistics', () async {
      final repository = FakeTaskRepository(
        tasks: [
          taskRow(
            id: 1,
            title: 'Today',
            dueDate: today,
            completed: true,
            completedAt: today,
          ),
          taskRow(
            id: 2,
            title: 'Yesterday',
            dueDate: today,
            completed: true,
            completedAt: today.subtract(const Duration(days: 1)),
          ),
          taskRow(
            id: 3,
            title: 'Two days ago',
            dueDate: today,
            completed: true,
            completedAt: today.subtract(const Duration(days: 2)),
          ),
          taskRow(id: 4, title: 'Pending', dueDate: today),
        ],
        subtasks: {
          1: [
            subtaskRow(id: 11, taskId: 1, title: 'Done', completed: true),
            subtaskRow(id: 12, taskId: 1, title: 'Open'),
          ],
          2: [
            subtaskRow(id: 21, taskId: 2, title: 'Done', completed: true),
          ],
        },
      );
      final state = TaskState(
        repository: repository,
        now: () => today,
        autoLoad: false,
      );
      await state.loadTasks();

      expect(state.totalTasks, 4);
      expect(state.completedTasks, 3);
      expect(state.completedTasksToday, 1);
      expect(state.pendingTasks, 1);
      expect(state.completedSubtasks, 2);
      expect(state.totalSubtasks, 3);
      expect(state.totalPoints, 40);
      expect(state.currentStreak, 3);
    });

    test('uses stable IDs for task and subtask mutations', () async {
      final repository = FakeTaskRepository(
        tasks: [taskRow(id: 40, title: 'Task', dueDate: today)],
        subtasks: {
          40: [subtaskRow(id: 99, taskId: 40, title: 'Step')],
        },
      );
      final state = TaskState(
        repository: repository,
        now: () => today,
        autoLoad: false,
      );
      await state.loadTasks();

      await state.toggleTaskCompletion(40);
      await state.toggleSubtaskCompletion(40, 99);
      await state.editSubtask(40, 99, 'Renamed');

      expect(state.tasks.single.isCompleted, isTrue);
      expect(state.tasks.single.completedAt, today);
      expect(state.tasks.single.subtasks.single.isCompleted, isTrue);
      expect(state.tasks.single.subtasks.single.title, 'Renamed');
    });

    test('stores task and subtask estimates', () async {
      final repository = FakeTaskRepository();
      final state = TaskState(repository: repository, autoLoad: false);

      await state.addTask('Estimated task', today, estimatedMinutes: 25);
      await state.addSubtask(100, 'Estimated step', estimatedMinutes: 10);
      await state.updateTaskEstimate(100, 5);
      await state.editSubtask(
        100,
        200,
        'Short step',
        estimatedMinutes: 2,
      );

      expect(state.tasks.single.estimatedMinutes, 5);
      expect(state.tasks.single.subtasks.single.title, 'Short step');
      expect(state.tasks.single.subtasks.single.estimatedMinutes, 2);
      expect(repository.taskRows.single['estimated_minutes'], 5);
      expect(repository.subtaskRows[100]!.single['estimated_minutes'], 2);

      await state.editSubtask(
        100,
        200,
        'No estimate step',
        clearEstimatedMinutes: true,
      );

      expect(state.tasks.single.subtasks.single.estimatedMinutes, isNull);
      expect(repository.subtaskRows[100]!.single['estimated_minutes'], isNull);
    });

    test('failed writes preserve in-memory state', () async {
      final repository = FakeTaskRepository(
        tasks: [taskRow(id: 1, title: 'Task', dueDate: today)],
        subtasks: {
          1: [subtaskRow(id: 2, taskId: 1, title: 'Step')],
        },
      );
      final state = TaskState(repository: repository, autoLoad: false);
      await state.loadTasks();
      repository.failWrites = true;

      await expectLater(state.toggleTaskCompletion(1), throwsStateError);
      await expectLater(state.toggleSubtaskCompletion(1, 2), throwsStateError);

      expect(state.tasks.single.isCompleted, isFalse);
      expect(state.tasks.single.subtasks.single.isCompleted, isFalse);
    });

    test('exposes an unmodifiable task collection', () async {
      final state = TaskState(
        repository: FakeTaskRepository(
          tasks: [taskRow(id: 1, title: 'Task', dueDate: today)],
        ),
        autoLoad: false,
      );
      await state.loadTasks();

      expect(() => state.tasks.clear(), throwsUnsupportedError);
    });

    test('missing IDs fail explicitly', () async {
      final state = TaskState(
        repository: FakeTaskRepository(),
        autoLoad: false,
      );

      await expectLater(state.toggleTaskCompletion(404), throwsStateError);
    });

    test('deletion returns a snapshot that can be restored', () async {
      final repository = FakeTaskRepository(
        tasks: [
          taskRow(
            id: 8,
            title: 'Recover me',
            dueDate: today,
            completed: true,
            completedAt: today,
            estimatedMinutes: 25,
          ),
        ],
        subtasks: {
          8: [
            subtaskRow(
              id: 9,
              taskId: 8,
              title: 'Recovered step',
              completed: true,
              estimatedMinutes: 10,
            ),
          ],
        },
      );
      final state = TaskState(repository: repository, autoLoad: false);
      await state.loadTasks();

      final deleted = await state.deleteTask(8);
      expect(state.tasks, isEmpty);

      await state.restoreTask(deleted);
      expect(state.tasks, hasLength(1));
      expect(state.tasks.single.title, 'Recover me');
      expect(state.tasks.single.isCompleted, isTrue);
      expect(state.tasks.single.estimatedMinutes, 25);
      expect(state.tasks.single.subtasks.single.title, 'Recovered step');
      expect(state.tasks.single.subtasks.single.isCompleted, isTrue);
      expect(state.tasks.single.subtasks.single.estimatedMinutes, 10);
    });

    test('saves support metadata and exposes a tiny next step', () async {
      final repository = FakeTaskRepository(
        tasks: [taskRow(id: 12, title: 'Write report', dueDate: today)],
      );
      final state = TaskState(repository: repository, autoLoad: false);
      await state.loadTasks();

      await state.updateTaskSupport(
        12,
        friction: TaskFriction.tooBig,
        energyLevel: TaskEnergyLevel.low,
        timeEstimate: TaskTimeEstimate.fiveMinutes,
        anxietyLevel: TaskAnxietyLevel.tense,
      );

      final task = state.tasks.single;
      expect(task.friction, TaskFriction.tooBig);
      expect(task.energyLevel, TaskEnergyLevel.low);
      expect(task.timeEstimate, TaskTimeEstimate.fiveMinutes);
      expect(task.anxietyLevel, TaskAnxietyLevel.tense);
      expect(task.tinyNextStep, contains('Write report'));
      expect(repository.taskRows.single['friction'], 'tooBig');
    });

    test('adds a tiny step only once', () async {
      final repository = FakeTaskRepository(
        tasks: [taskRow(id: 14, title: 'Start essay', dueDate: today)],
      );
      final state = TaskState(repository: repository, autoLoad: false);
      await state.loadTasks();

      expect(await state.addTinyStep(14), isTrue);
      expect(await state.addTinyStep(14), isFalse);

      expect(repository.subtaskRows[14], hasLength(1));
      expect(
        repository.subtaskRows[14]!.single['title'],
        'Open "Start essay" and do one visible next step.',
      );
    });

    test('uses the first incomplete subtask as the tiny-step suggestion',
        () async {
      final repository = FakeTaskRepository(
        tasks: [taskRow(id: 15, title: 'Research paper', dueDate: today)],
        subtasks: {
          15: [
            subtaskRow(
              id: 31,
              taskId: 15,
              title: 'Pick a topic',
              completed: true,
            ),
            subtaskRow(id: 32, taskId: 15, title: 'Find one source'),
          ],
        },
      );
      final state = TaskState(repository: repository, autoLoad: false);
      await state.loadTasks();

      final task = state.tasks.single;
      expect(state.tinyStepSuggestionFor(task), 'Find one source');
      expect(await state.addTinyStep(15), isFalse);
      expect(repository.subtaskRows[15], hasLength(2));
    });
  });
}
