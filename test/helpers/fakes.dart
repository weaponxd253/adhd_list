import 'package:adhd_list/repositories/repositories.dart';
import 'package:adhd_list/services/task_reminder_notification_service.dart';
import 'package:adhd_list/services/timer_notification_service.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({
    List<Map<String, dynamic>>? tasks,
    Map<int, List<Map<String, dynamic>>>? subtasks,
  })  : taskRows = tasks ?? [],
        subtaskRows = subtasks ?? {};

  List<Map<String, dynamic>> taskRows;
  Map<int, List<Map<String, dynamic>>> subtaskRows;
  bool failReads = false;
  bool failWrites = false;
  int nextTaskId = 100;
  int nextSubtaskId = 200;

  Never _failure() => throw StateError('write failed');
  Never _readFailure() => throw StateError('read failed');

  @override
  Future<void> clearTasks() async {
    if (failWrites) _failure();
    taskRows = [];
    subtaskRows = {};
  }

  @override
  Future<void> deleteSubtask(int subtaskId) async {
    if (failWrites) _failure();
    for (final rows in subtaskRows.values) {
      rows.removeWhere((row) => row['id'] == subtaskId);
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    if (failWrites) _failure();
    taskRows.removeWhere((row) => row['id'] == id);
    subtaskRows.remove(id);
  }

  @override
  Future<void> editTask(int id, String title, String dueDate) async {
    if (failWrites) _failure();
    final row = taskRows.firstWhere((row) => row['id'] == id);
    row['title'] = title;
    row['due_date'] = dueDate;
  }

  @override
  Future<void> updateTaskEstimate(int taskId, int? estimatedMinutes) async {
    if (failWrites) _failure();
    final row = taskRows.firstWhere((row) => row['id'] == taskId);
    row['estimated_minutes'] = estimatedMinutes;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSubtasks(int taskId) async {
    if (failReads) _readFailure();
    return subtaskRows[taskId]?.map(Map<String, dynamic>.from).toList() ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTasks() async {
    if (failReads) _readFailure();
    return taskRows.map(Map<String, dynamic>.from).toList();
  }

  @override
  Future<int> insertSubtask(
    int taskId,
    String title, {
    int? estimatedMinutes,
  }) async {
    if (failWrites) _failure();
    final id = nextSubtaskId++;
    subtaskRows.putIfAbsent(taskId, () => []).add({
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': 0,
      'estimated_minutes': estimatedMinutes,
    });
    return id;
  }

  @override
  Future<int> insertTask(
    String title,
    String dueDate, {
    int? estimatedMinutes,
  }) async {
    if (failWrites) _failure();
    final id = nextTaskId++;
    taskRows.add({
      'id': id,
      'title': title,
      'due_date': dueDate,
      'is_completed': 0,
      'status': 'pending',
      'completed_at': null,
      'estimated_minutes': estimatedMinutes,
    });
    return id;
  }

  @override
  Future<void> updateSubtask(
    int subtaskId,
    String title, {
    int? estimatedMinutes,
  }) async {
    if (failWrites) _failure();
    for (final rows in subtaskRows.values) {
      for (final row in rows) {
        if (row['id'] == subtaskId) {
          row['title'] = title;
          row['estimated_minutes'] = estimatedMinutes;
        }
      }
    }
  }

  @override
  Future<void> updateSubtaskStatus(
    int subtaskId,
    bool isCompleted,
  ) async {
    if (failWrites) _failure();
    for (final rows in subtaskRows.values) {
      for (final row in rows) {
        if (row['id'] == subtaskId) {
          row['is_completed'] = isCompleted ? 1 : 0;
        }
      }
    }
  }

  @override
  Future<void> updateTaskStatus(int taskId, String status) async {
    if (failWrites) _failure();
    final row = taskRows.firstWhere((row) => row['id'] == taskId);
    row['status'] = status;
    row['is_completed'] = status == 'completed' ? 1 : 0;
  }

  @override
  Future<void> updateTaskSupport(
    int taskId, {
    String? friction,
    String? energyLevel,
    String? timeEstimate,
    String? anxietyLevel,
  }) async {
    if (failWrites) _failure();
    final row = taskRows.firstWhere((row) => row['id'] == taskId);
    row['friction'] = friction;
    row['energy_level'] = energyLevel;
    row['time_estimate'] = timeEstimate;
    row['anxiety_level'] = anxietyLevel;
  }
}

class FakeTaskReminderRepository implements TaskReminderRepository {
  FakeTaskReminderRepository({List<Map<String, dynamic>>? reminders})
      : reminderRows = reminders ?? [];

  List<Map<String, dynamic>> reminderRows;
  bool failReads = false;
  bool failWrites = false;

  Never _failure() => throw StateError('task reminder failure');

  @override
  Future<void> clearTaskReminders() async {
    if (failWrites) _failure();
    reminderRows = [];
  }

  @override
  Future<void> deleteTaskReminder(int taskId) async {
    if (failWrites) _failure();
    reminderRows.removeWhere((row) => row['task_id'] == taskId);
  }

  @override
  Future<Map<String, dynamic>?> fetchTaskReminder(int taskId) async {
    if (failReads) _failure();
    for (final row in reminderRows) {
      if (row['task_id'] == taskId) return Map<String, dynamic>.from(row);
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTaskReminders() async {
    if (failReads) _failure();
    return reminderRows.map(Map<String, dynamic>.from).toList();
  }

  @override
  Future<void> upsertTaskReminder({
    required int taskId,
    required String style,
    required String scheduledAt,
    bool enabled = true,
  }) async {
    if (failWrites) _failure();
    reminderRows.removeWhere((row) => row['task_id'] == taskId);
    reminderRows.add({
      'task_id': taskId,
      'style': style,
      'scheduled_at': scheduledAt,
      'enabled': enabled ? 1 : 0,
    });
  }
}

class FakeMoodRepository implements MoodRepository {
  FakeMoodRepository({List<Map<String, dynamic>>? entries})
      : entries = entries ?? [];

  List<Map<String, dynamic>> entries;
  bool failWrites = false;

  @override
  Future<void> clearMoods() async {
    if (failWrites) throw StateError('write failed');
    entries = [];
  }

  @override
  Future<Map<String, dynamic>?> fetchLastMood() async =>
      entries.isEmpty ? null : Map<String, dynamic>.from(entries.first);

  @override
  Future<List<Map<String, dynamic>>> fetchMoods() async =>
      entries.map(Map<String, dynamic>.from).toList();

  @override
  Future<int> insertMood(String mood, String emoji) async {
    if (failWrites) throw StateError('write failed');
    entries.insert(0, {
      'id': entries.length + 1,
      'mood': mood,
      'emoji': emoji,
      'date': DateTime(2026, 6, 23).toIso8601String(),
    });
    return entries.first['id'] as int;
  }
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.value,
    Map<String, String>? values,
  }) : values = values ?? {};

  String? value;
  Map<String, String> values;
  bool failWrites = false;

  @override
  Future<String?> read(String key) async => values[key] ?? value;

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('write failed');
    this.value = value;
    values[key] = value;
  }
}

class FakeTimerSessionRepository implements TimerSessionRepository {
  FakeTimerSessionRepository({List<Map<String, Object?>>? sessions})
      : sessionRows = sessions ?? [];

  List<Map<String, Object?>> sessionRows;
  bool failReads = false;
  bool failWrites = false;
  int nextSessionId = 1;

  Never _failure() => throw StateError('timer session failure');

  @override
  Future<void> clearSessions() async {
    if (failWrites) _failure();
    sessionRows = [];
  }

  @override
  Future<List<Map<String, Object?>>> fetchSessions({int limit = 60}) async {
    if (failReads) _failure();
    final rows = sessionRows.map(Map<String, Object?>.from).toList()
      ..sort(
        (a, b) => (b['ended_at'] as String).compareTo(a['ended_at'] as String),
      );
    return rows.take(limit).toList();
  }

  @override
  Future<int> insertSession(Map<String, Object?> session) async {
    if (failWrites) _failure();
    final id = nextSessionId++;
    sessionRows.insert(0, {...session, 'id': id});
    return id;
  }

  @override
  Future<void> updateSessionOutcome(int sessionId, String outcome) async {
    if (failWrites) _failure();
    for (final row in sessionRows) {
      if (row['id'] == sessionId) {
        row['outcome'] = outcome;
        return;
      }
    }
    _failure();
  }
}

class FakeTimerNotificationService implements TimerNotificationService {
  bool permissionGranted = true;
  int permissionRequests = 0;
  int cancelCount = 0;
  final scheduled = <Map<String, Object?>>[];

  @override
  Future<void> cancelTimerCompletion() async {
    cancelCount++;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleTimerCompletion({
    required DateTime when,
    required String title,
    required String body,
  }) async {
    scheduled.add({
      'when': when,
      'title': title,
      'body': body,
    });
  }
}

class FakeTaskReminderNotificationService
    implements TaskReminderNotificationService {
  bool permissionGranted = true;
  int permissionRequests = 0;
  int cancelAllCount = 0;
  final canceledTaskIds = <int>[];
  final scheduled = <Map<String, Object?>>[];

  @override
  Future<void> cancelAllTaskReminders() async {
    cancelAllCount++;
  }

  @override
  Future<void> cancelTaskReminder(int taskId) async {
    canceledTaskIds.add(taskId);
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleTaskReminder({
    required int taskId,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    scheduled.add({
      'taskId': taskId,
      'when': when,
      'title': title,
      'body': body,
    });
  }
}

Map<String, dynamic> taskRow({
  required int id,
  required String title,
  required DateTime dueDate,
  bool completed = false,
  DateTime? completedAt,
  int? estimatedMinutes,
}) {
  return {
    'id': id,
    'title': title,
    'due_date': dueDate.toIso8601String(),
    'is_completed': completed ? 1 : 0,
    'status': completed ? 'completed' : 'pending',
    'completed_at': completedAt?.toIso8601String(),
    'friction': null,
    'energy_level': null,
    'time_estimate': null,
    'anxiety_level': null,
    'estimated_minutes': estimatedMinutes,
  };
}

Map<String, dynamic> subtaskRow({
  required int id,
  required int taskId,
  required String title,
  bool completed = false,
  int? estimatedMinutes,
}) {
  return {
    'id': id,
    'task_id': taskId,
    'title': title,
    'is_completed': completed ? 1 : 0,
    'estimated_minutes': estimatedMinutes,
  };
}
