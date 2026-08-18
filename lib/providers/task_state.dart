import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../database/task_database.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../models/task_support.dart';
import '../repositories/repositories.dart';
import '../services/task_reminder_notification_service.dart';

class TaskState extends ChangeNotifier {
  TaskState({
    TaskRepository? repository,
    TaskReminderRepository? taskReminderRepository,
    TaskReminderNotificationService? taskReminderNotificationService,
    DateTime Function()? now,
    bool autoLoad = true,
  })  : _repository = repository ?? TaskDatabase(),
        _taskReminderRepository = taskReminderRepository,
        _taskReminderNotificationService = taskReminderNotificationService,
        _now = now ?? DateTime.now {
    if (autoLoad) unawaited(loadTasks());
  }

  final TaskRepository _repository;
  final TaskReminderRepository? _taskReminderRepository;
  final TaskReminderNotificationService? _taskReminderNotificationService;
  final DateTime Function() _now;
  List<Task> _tasks = [];
  final Set<int> _busyTaskIds = {};
  int? _tomorrowStarterTaskId;
  bool _isLoading = false;
  bool _isCreating = false;
  String? _loadError;

  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get loadError => _loadError;
  bool isTaskBusy(int taskId) => _busyTaskIds.contains(taskId);

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
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
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
            friction: taskFrictionFromId(row['friction'] as String?),
            energyLevel: taskEnergyLevelFromId(row['energy_level'] as String?),
            timeEstimate:
                taskTimeEstimateFromId(row['time_estimate'] as String?),
            anxietyLevel:
                taskAnxietyLevelFromId(row['anxiety_level'] as String?),
            estimatedMinutes: row['estimated_minutes'] as int?,
            subtasks: subtaskRows.map(Subtask.fromMap).toList(),
          ),
        );
      }
      _tasks = loaded;
    } catch (_) {
      _loadError = 'Could not load tasks. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(
    String title,
    DateTime dueDate, {
    int? estimatedMinutes,
  }) async {
    _isCreating = true;
    notifyListeners();
    try {
      await _repository.insertTask(
        title,
        dueDate.toIso8601String(),
        estimatedMinutes: estimatedMinutes,
      );
      await loadTasks();
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<void> clearTaskHistory() async {
    await _cancelAllTaskReminders();
    await _repository.clearTasks();
    _tasks = [];
    _tomorrowStarterTaskId = null;
    notifyListeners();
  }

  Future<void> editTask(
    int taskId,
    String title,
    DateTime dueDate,
  ) async {
    await _runTaskMutation(taskId, () async {
      await _repository.editTask(taskId, title, dueDate.toIso8601String());
      await loadTasks();
    });
  }

  Future<Task> deleteTask(int taskId) async {
    final task = _copyTask(_requireTask(taskId));
    await _runTaskMutation(taskId, () async {
      await _cancelReminderForTask(taskId);
      await _repository.deleteTask(taskId);
      _tasks = _tasks.where((item) => item.id != taskId).toList();
      if (_tomorrowStarterTaskId == taskId) _tomorrowStarterTaskId = null;
    });
    return task;
  }

  Future<void> restoreTask(Task task) async {
    _isCreating = true;
    notifyListeners();
    try {
      final taskId = await _repository.insertTask(
        task.title,
        task.dueDate.toIso8601String(),
        estimatedMinutes: task.estimatedMinutes,
      );
      if (task.isCompleted) {
        await _repository.updateTaskStatus(taskId, 'completed');
      }
      await _repository.updateTaskSupport(
        taskId,
        friction: task.friction?.id,
        energyLevel: task.energyLevel?.id,
        timeEstimate: task.timeEstimate?.id,
        anxietyLevel: task.anxietyLevel?.id,
      );
      for (final subtask in task.subtasks) {
        final subtaskId = await _repository.insertSubtask(
          taskId,
          subtask.title,
          estimatedMinutes: subtask.estimatedMinutes,
        );
        if (subtask.isCompleted) {
          await _repository.updateSubtaskStatus(subtaskId, true);
        }
      }
      await loadTasks();
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(int taskId) async {
    final task = _requireTask(taskId);
    await _setTaskCompletion(task, completed: !task.isCompleted);
  }

  Future<bool> markTaskCompleted(int taskId) async {
    final task = _requireTask(taskId);
    if (task.isCompleted) return false;
    await _setTaskCompletion(task, completed: true);
    return true;
  }

  Future<void> completeTask(int taskId) async {
    final task = _requireTask(taskId);
    if (task.isCompleted) return;

    await _runTaskMutation(taskId, () async {
      await _repository.updateTaskStatus(taskId, 'completed');
      task.status = 'completed';
      task.completedAt = _now();
      if (_tomorrowStarterTaskId == taskId) _tomorrowStarterTaskId = null;
      await _cancelReminderForTask(taskId);
    });
  }

  Future<void> moveTaskToLater(int taskId, {int days = 7}) async {
    final task = _requireTask(taskId);
    final now = _now();
    final later = DateTime(now.year, now.month, now.day).add(
      Duration(days: days),
    );
    await _runTaskMutation(taskId, () async {
      await _repository.editTask(taskId, task.title, later.toIso8601String());
      await _cancelReminderForTask(taskId);
      await loadTasks();
    });
  }

  void setTomorrowStarter(int taskId) {
    final task = _requireTask(taskId);
    if (task.isCompleted) {
      throw StateError('Completed tasks cannot be tomorrow starters.');
    }
    if (_tomorrowStarterTaskId == taskId) return;
    _tomorrowStarterTaskId = taskId;
    notifyListeners();
  }

  void clearTomorrowStarter() {
    if (_tomorrowStarterTaskId == null) return;
    _tomorrowStarterTaskId = null;
    notifyListeners();
  }

  Future<void> updateTaskSupport(
    int taskId, {
    TaskFriction? friction,
    TaskEnergyLevel? energyLevel,
    TaskTimeEstimate? timeEstimate,
    TaskAnxietyLevel? anxietyLevel,
  }) async {
    final task = _requireTask(taskId);
    await _runTaskMutation(taskId, () async {
      await _repository.updateTaskSupport(
        taskId,
        friction: friction?.id,
        energyLevel: energyLevel?.id,
        timeEstimate: timeEstimate?.id,
        anxietyLevel: anxietyLevel?.id,
      );
      task.friction = friction;
      task.energyLevel = energyLevel;
      task.timeEstimate = timeEstimate;
      task.anxietyLevel = anxietyLevel;
    });
  }

  Future<void> updateTaskEstimate(int taskId, int? estimatedMinutes) async {
    final task = _requireTask(taskId);
    await _runTaskMutation(taskId, () async {
      await _repository.updateTaskEstimate(taskId, estimatedMinutes);
      task.estimatedMinutes = estimatedMinutes;
    });
  }

  Future<void> addSubtask(
    int taskId,
    String title, {
    int? estimatedMinutes,
  }) async {
    final task = _requireTask(taskId);
    await _runTaskMutation(taskId, () async {
      final id = await _repository.insertSubtask(
        taskId,
        title,
        estimatedMinutes: estimatedMinutes,
      );
      task.subtasks.add(
        Subtask(id: id, title: title, estimatedMinutes: estimatedMinutes),
      );
    });
  }

  Future<bool> addTinyStep(int taskId) async {
    final task = _requireTask(taskId);
    final title = _tinyStepTitle(task);
    if (_hasSubtaskTitle(task, title)) return false;

    await _runTaskMutation(taskId, () async {
      final id = await _repository.insertSubtask(taskId, title);
      task.subtasks.add(Subtask(id: id, title: title));
    });
    return true;
  }

  String tinyStepSuggestionFor(Task task) => _tinyStepTitle(task);

  Future<void> editSubtask(
    int taskId,
    int subtaskId,
    String title, {
    int? estimatedMinutes,
    bool clearEstimatedMinutes = false,
  }) async {
    final task = _requireTask(taskId);
    final subtask = _requireSubtask(task, subtaskId);
    final nextEstimatedMinutes = clearEstimatedMinutes
        ? null
        : estimatedMinutes ?? subtask.estimatedMinutes;
    await _runTaskMutation(taskId, () async {
      await _repository.updateSubtask(
        subtaskId,
        title,
        estimatedMinutes: nextEstimatedMinutes,
      );
      subtask.title = title;
      subtask.estimatedMinutes = nextEstimatedMinutes;
    });
  }

  Future<void> deleteSubtask(int taskId, int subtaskId) async {
    final task = _requireTask(taskId);
    _requireSubtask(task, subtaskId);
    await _runTaskMutation(taskId, () async {
      await _repository.deleteSubtask(subtaskId);
      task.subtasks.removeWhere((item) => item.id == subtaskId);
    });
  }

  Future<void> toggleSubtaskCompletion(int taskId, int subtaskId) async {
    final task = _requireTask(taskId);
    final subtask = _requireSubtask(task, subtaskId);
    final completed = !subtask.isCompleted;
    await _runTaskMutation(taskId, () async {
      await _repository.updateSubtaskStatus(subtaskId, completed);
      subtask.isCompleted = completed;
    });
  }

<<<<<<< HEAD
  Future<bool> markSubtaskCompleted(int taskId, int subtaskId) async {
    final task = _requireTask(taskId);
    final subtask = _requireSubtask(task, subtaskId);
    if (subtask.isCompleted) return false;
=======
  Future<void> completeSubtask(int taskId, int subtaskId) async {
    final task = _requireTask(taskId);
    final subtask = _requireSubtask(task, subtaskId);
    if (subtask.isCompleted) return;
>>>>>>> 116293643c717f05e5b4aafac370a2efdd93a2e1

    await _runTaskMutation(taskId, () async {
      await _repository.updateSubtaskStatus(subtaskId, true);
      subtask.isCompleted = true;
    });
<<<<<<< HEAD
    return true;
  }

  Future<void> _setTaskCompletion(
    Task task, {
    required bool completed,
  }) async {
    final status = completed ? 'completed' : 'pending';
    await _runTaskMutation(task.id, () async {
      await _repository.updateTaskStatus(task.id, status);
      task.status = status;
      task.completedAt = completed ? _now() : null;
      if (completed && _tomorrowStarterTaskId == task.id) {
        _tomorrowStarterTaskId = null;
      }
      if (completed) await _cancelReminderForTask(task.id);
    });
=======
>>>>>>> 116293643c717f05e5b4aafac370a2efdd93a2e1
  }

  Future<void> _runTaskMutation(
    int taskId,
    Future<void> Function() operation,
  ) async {
    _busyTaskIds.add(taskId);
    notifyListeners();
    try {
      await operation();
    } finally {
      _busyTaskIds.remove(taskId);
      notifyListeners();
    }
  }

  Future<void> _cancelReminderForTask(int taskId) async {
    final notificationService = _taskReminderNotificationService;
    final reminderRepository = _taskReminderRepository;

    try {
      await notificationService?.cancelTaskReminder(taskId);
    } catch (_) {}

    try {
      await reminderRepository?.deleteTaskReminder(taskId);
    } catch (_) {}
  }

  Future<void> _cancelAllTaskReminders() async {
    final notificationService = _taskReminderNotificationService;
    final reminderRepository = _taskReminderRepository;

    try {
      await notificationService?.cancelAllTaskReminders();
    } catch (_) {}

    try {
      await reminderRepository?.clearTaskReminders();
    } catch (_) {}
  }

  Task _copyTask(Task task) {
    return Task(
      id: task.id,
      title: task.title,
      dueDate: task.dueDate,
      status: task.status,
      completedAt: task.completedAt,
      friction: task.friction,
      energyLevel: task.energyLevel,
      timeEstimate: task.timeEstimate,
      anxietyLevel: task.anxietyLevel,
      estimatedMinutes: task.estimatedMinutes,
      subtasks: task.subtasks
          .map(
            (subtask) => Subtask(
              id: subtask.id,
              title: subtask.title,
              isCompleted: subtask.isCompleted,
              estimatedMinutes: subtask.estimatedMinutes,
            ),
          )
          .toList(),
    );
  }

  List<Task> _sortedPendingTasks() {
    return _tasks.where((task) => !task.isCompleted).toList()
      ..sort((a, b) {
        final byDueDate = a.dueDate.compareTo(b.dueDate);
        if (byDueDate != 0) return byDueDate;
        return a.id.compareTo(b.id);
      });
  }

  List<Task> _sortedCompletedTasks() {
    return _tasks.where((task) => task.isCompleted).toList()
      ..sort((a, b) {
        final aDate = a.completedAt ?? DateTime(1970);
        final bDate = b.completedAt ?? DateTime(1970);
        final byCompletedDate = bDate.compareTo(aDate);
        if (byCompletedDate != 0) return byCompletedDate;
        return b.id.compareTo(a.id);
      });
  }

  String _tinyStepTitle(Task task) {
    final existingStep = _firstIncompleteSubtask(task);
    if (existingStep != null) return existingStep.title;

    return task.tinyNextStep ??
        'Open "${task.title}" and do one visible next step.';
  }

  Subtask? _firstIncompleteSubtask(Task task) {
    for (final subtask in task.subtasks) {
      if (!subtask.isCompleted) return subtask;
    }
    return null;
  }

  bool _hasSubtaskTitle(Task task, String title) {
    final normalized = title.trim().toLowerCase();
    return task.subtasks.any(
      (subtask) => subtask.title.trim().toLowerCase() == normalized,
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  int _calendarDayDifference(DateTime date) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(date.year, date.month, date.day).difference(today).inDays;
  }

  bool _hasCompletedSubtask(Task task) {
    return task.subtasks.any((subtask) => subtask.isCompleted);
  }

  bool _isWaitingTask(Task task) {
    return !task.isCompleted &&
        _calendarDayDifference(task.dueDate) <= -2 &&
        !_hasCompletedSubtask(task);
  }

  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => _tasks.where((task) => !task.isCompleted).length;
  int get completedTasksToday {
    final today = _now();
    return _tasks.where((task) {
      final completedAt = task.completedAt;
      return task.isCompleted &&
          completedAt != null &&
          _isSameDay(completedAt, today);
    }).length;
  }

  List<Task> get pendingTaskList => List.unmodifiable(_sortedPendingTasks());

  Task? get waitingTask {
    for (final task in _sortedPendingTasks()) {
      if (_isWaitingTask(task)) return task;
    }
    return null;
  }

  List<Task> get tomorrowStarterOptions =>
      List.unmodifiable(_sortedPendingTasks().take(5));

  Task? get selectedTomorrowStarterTask {
    final taskId = _tomorrowStarterTaskId;
    if (taskId == null) return null;
    for (final task in _tasks) {
      if (task.id == taskId && !task.isCompleted) return task;
    }
    return null;
  }

  Task? get tomorrowStarterTask {
    final selected = selectedTomorrowStarterTask;
    if (selected != null) return selected;
    return nowTask ?? (nextTasks.isEmpty ? null : nextTasks.first);
  }

  Task? get nowTask {
    final pending = _sortedPendingTasks();
    return pending.isEmpty ? null : pending.first;
  }

  List<Task> get nextTasks {
    final pending = _sortedPendingTasks();
    return List.unmodifiable(pending.skip(1).take(2));
  }

  List<Task> get laterTasks {
    final pending = _sortedPendingTasks();
    return List.unmodifiable(pending.skip(3));
  }

  int get laterTaskCount => laterTasks.length;

  List<Task> get upcomingTasks {
    final pending = _sortedPendingTasks();
    return List.unmodifiable(pending.take(3));
  }

  List<Task> get completedTaskList =>
      List.unmodifiable(_sortedCompletedTasks());

  int get completedSubtasks => _tasks.fold(
        0,
        (sum, task) =>
            sum + task.subtasks.where((subtask) => subtask.isCompleted).length,
      );

  int get totalSubtasks => _tasks.fold(
        0,
        (sum, task) => sum + task.subtasks.length,
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
