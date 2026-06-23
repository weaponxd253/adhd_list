import 'database_helper.dart';
import '../repositories/repositories.dart';

class TaskDatabase implements TaskRepository {
  TaskDatabase({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper dbHelper;

  void _requireAffectedRow(int count, String operation) {
    if (count == 0) {
      throw StateError('$operation did not match an existing record.');
    }
  }

  @override
  Future<int> insertTask(String title, String dueDate) async {
    final db = await dbHelper.database;
    return await db.insert(
      'tasks',
      {
        'title': title,
        'due_date': dueDate,
        'is_completed': 0,
        'status': 'pending',
        'completed_at': null,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final db = await dbHelper.database;
    return await db.query('tasks');
  }

  @override
  Future<void> editTask(int id, String newTitle, String newDueDate) async {
    final db = await dbHelper.database;
    final count = await db.update(
      'tasks',
      {'title': newTitle, 'due_date': newDueDate},
      where: 'id = ?',
      whereArgs: [id],
    );
    _requireAffectedRow(count, 'Editing task $id');
  }

  // Keeps is_completed, status, and completed_at in sync.
  // completed_at is stamped when the task is first marked done and cleared
  // if the task is un-completed, so the streak reflects actual completion days.
  @override
  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    final db = await dbHelper.database;
    final count = await db.update(
      'tasks',
      {
        'status': newStatus,
        'is_completed': newStatus == 'completed' ? 1 : 0,
        'completed_at':
            newStatus == 'completed' ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
    _requireAffectedRow(count, 'Updating task $taskId');
  }

  @override
  Future<void> deleteTask(int id) async {
    final db = await dbHelper.database;
    final count = await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    _requireAffectedRow(count, 'Deleting task $id');
  }

  @override
  Future<void> clearTasks() async {
    final db = await dbHelper.database;
    await db.delete('tasks');
  }

  @override
  Future<int> insertSubtask(int taskId, String title) async {
    final db = await dbHelper.database;
    return await db.insert(
      'subtasks',
      {'task_id': taskId, 'title': title, 'is_completed': 0},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSubtasks(int taskId) async {
    final db = await dbHelper.database;
    return await db.query(
      'subtasks',
      columns: ['id', 'task_id', 'title', 'is_completed'],
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  @override
  Future<void> updateSubtask(int subtaskId, String newTitle) async {
    final db = await dbHelper.database;
    final count = await db.update(
      'subtasks',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [subtaskId],
    );
    _requireAffectedRow(count, 'Editing subtask $subtaskId');
  }

  // Persists subtask completion state.
  @override
  Future<void> updateSubtaskStatus(int subtaskId, bool isCompleted) async {
    final db = await dbHelper.database;
    final count = await db.update(
      'subtasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [subtaskId],
    );
    _requireAffectedRow(count, 'Updating subtask $subtaskId');
  }

  @override
  Future<void> deleteSubtask(int subtaskId) async {
    final db = await dbHelper.database;
    final count = await db.delete(
      'subtasks',
      where: 'id = ?',
      whereArgs: [subtaskId],
    );
    _requireAffectedRow(count, 'Deleting subtask $subtaskId');
  }
}
