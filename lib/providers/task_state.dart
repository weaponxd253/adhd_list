import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../database/task_database.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../repositories/repositories.dart';

class TaskState extends ChangeNotifier {
  TaskState({
    TaskRepository? repository,
    DateTime Function()? now,
    bool autoLoad = true,
  })  : _repository = repository ?? TaskDatabase(),
        _now = now ?? DateTime.now {
    if (autoLoad) unawaited(loadTasks());
  }

  final TaskRepository _repository;
  final DateTime Function() _now;
  List<Task> _tasks = [];

  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  Task _requireTask(int taskId) {
    for (final task in _tasks) {
      if (task.id == taskId) return task;
    }
    throw StateError('Task $taskId is no longer available.');
  }

  Subtask _requireSubtask(Task task, int subtaskId) {
    for (final subtask in task.subtasks) {
      if (subtask.id == subtaskId) return subtask;
    }
    throw StateError('Subtask $subtaskId is no longer available.');
  }

  Future<void> loadTasks() async {
    final rows = await _repository.fetchTasks();
    final loaded = <Task>[];
    for (final row in rows) {
      final subtaskRows = await _repository.fetchSubtasks(row['id'] as int);
      loaded.add(
        Task(
          id: row['id'] as int,
          title: row['title'] as String,
          dueDate: DateTime.parse(row['due_date'] as String),
          status: row['is_completed'] == 1 ? 'completed' : 'pending',
          completedAt: row['completed_at'] == null
              ? null
              : DateTime.tryParse(row['completed_at'] as String),
          subtasks: subtaskRows.map(Subtask.fromMap).toList(),
        ),
      );
    }
    _tasks = loaded;
    notifyListeners();
  }

  Future<void> addTask(String title, DateTime dueDate) async {
    await _repository.insertTask(title, dueDate.toIso8601String());
    await loadTasks();
  }

  Future<void> clearTaskHistory() async {
    await _repository.clearTasks();
    _tasks = [];
    notifyListeners();
  }

  Future<void> editTask(
    int taskId,
    String title,
    DateTime dueDate,
  ) async {
    await _repository.editTask(taskId, title, dueDate.toIso8601String());
    await loadTasks();
  }

  Future<void> deleteTask(int taskId) async {
    await _repository.deleteTask(taskId);
    _tasks = _tasks.where((task) => task.id != taskId).toList();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(int taskId) async {
    final task = _requireTask(taskId);
    final status = task.isCompleted ? 'pending' : 'completed';
    await _repository.updateTaskStatus(taskId, status);
    task.status = status;
    task.completedAt = status == 'completed' ? _now() : null;
    notifyListeners();
  }

  Future<void> addSubtask(int taskId, String title) async {
    final task = _requireTask(taskId);
    final id = await _repository.insertSubtask(taskId, title);
    task.subtasks.add(Subtask(id: id, title: title));
    notifyListeners();
  }

  Future<void> editSubtask(
    int taskId,
    int subtaskId,
    String title,
  ) async {
    final task = _requireTask(taskId);
    final subtask = _requireSubtask(task, subtaskId);
    await _repository.updateSubtask(subtaskId, title);
    subtask.title = title;
    notifyListeners();
  }

  Future<void> deleteSubtask(int taskId, int subtaskId) async {
    final task = _requireTask(taskId);
    _requireSubtask(task, subtaskId);
    await _repository.deleteSubtask(subtaskId);
    task.subtasks.removeWhere((item) => item.id == subtaskId);
    notifyListeners();
  }

  Future<void> toggleSubtaskCompletion(int taskId, int subtaskId) async {
    final task = _requireTask(taskId);
    final subtask = _requireSubtask(task, subtaskId);
    final completed = !subtask.isCompleted;
    await _repository.updateSubtaskStatus(subtaskId, completed);
    subtask.isCompleted = completed;
    notifyListeners();
  }

  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => _tasks.where((task) => !task.isCompleted).length;

  List<Task> get upcomingTasks {
    final pending = _tasks.where((task) => !task.isCompleted).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return List.unmodifiable(pending.take(3));
  }

  List<Task> get completedTaskList =>
      List.unmodifiable(_tasks.where((task) => task.isCompleted));

  int get completedSubtasks => _tasks.fold(
        0,
        (sum, task) =>
            sum + task.subtasks.where((subtask) => subtask.isCompleted).length,
      );

  int get totalPoints => (completedTasks * 10) + (completedSubtasks * 5);

  int get currentStreak {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final completionDays = _tasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .map((task) {
          final date = task.completedAt!;
          return DateTime(date.year, date.month, date.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (completionDays.isEmpty) return 0;
    if (today.difference(completionDays.first).inDays > 1) return 0;

    var streak = 1;
    for (var i = 1; i < completionDays.length; i++) {
      if (completionDays[i - 1].difference(completionDays[i]).inDays != 1) {
        break;
      }
      streak++;
    }
    return streak;
  }
}
