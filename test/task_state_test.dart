import 'package:adhd_list/providers/task_state.dart';
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
      expect(state.pendingTasks, 1);
      expect(state.completedSubtasks, 2);
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
  });
}
