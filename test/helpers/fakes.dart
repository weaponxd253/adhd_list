import 'package:adhd_list/repositories/repositories.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({
    List<Map<String, dynamic>>? tasks,
    Map<int, List<Map<String, dynamic>>>? subtasks,
  })  : taskRows = tasks ?? [],
        subtaskRows = subtasks ?? {};

  List<Map<String, dynamic>> taskRows;
  Map<int, List<Map<String, dynamic>>> subtaskRows;
  bool failWrites = false;
  int nextTaskId = 100;
  int nextSubtaskId = 200;

  Never _failure() => throw StateError('write failed');

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
  Future<List<Map<String, dynamic>>> fetchSubtasks(int taskId) async =>
      subtaskRows[taskId]?.map(Map<String, dynamic>.from).toList() ?? [];

  @override
  Future<List<Map<String, dynamic>>> fetchTasks() async =>
      taskRows.map(Map<String, dynamic>.from).toList();

  @override
  Future<int> insertSubtask(int taskId, String title) async {
    if (failWrites) _failure();
    final id = nextSubtaskId++;
    subtaskRows.putIfAbsent(taskId, () => []).add({
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': 0,
    });
    return id;
  }

  @override
  Future<int> insertTask(String title, String dueDate) async {
    if (failWrites) _failure();
    final id = nextTaskId++;
    taskRows.add({
      'id': id,
      'title': title,
      'due_date': dueDate,
      'is_completed': 0,
      'status': 'pending',
      'completed_at': null,
    });
    return id;
  }

  @override
  Future<void> updateSubtask(int subtaskId, String title) async {
    if (failWrites) _failure();
    for (final rows in subtaskRows.values) {
      for (final row in rows) {
        if (row['id'] == subtaskId) row['title'] = title;
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
  FakeSettingsRepository({this.value});

  String? value;
  bool failWrites = false;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('write failed');
    this.value = value;
  }
}

Map<String, dynamic> taskRow({
  required int id,
  required String title,
  required DateTime dueDate,
  bool completed = false,
  DateTime? completedAt,
}) {
  return {
    'id': id,
    'title': title,
    'due_date': dueDate.toIso8601String(),
    'is_completed': completed ? 1 : 0,
    'status': completed ? 'completed' : 'pending',
    'completed_at': completedAt?.toIso8601String(),
  };
}

Map<String, dynamic> subtaskRow({
  required int id,
  required int taskId,
  required String title,
  bool completed = false,
}) {
  return {
    'id': id,
    'task_id': taskId,
    'title': title,
    'is_completed': completed ? 1 : 0,
  };
}
