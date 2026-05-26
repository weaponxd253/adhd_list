import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class TaskDatabase {
  final dbHelper = DatabaseHelper.instance;

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

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final db = await dbHelper.database;
    return await db.query('tasks');
  }

  Future<int> editTask(int id, String newTitle, String newDueDate) async {
    final db = await dbHelper.database;
    return await db.update(
      'tasks',
      {'title': newTitle, 'due_date': newDueDate},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Keeps is_completed, status, and completed_at in sync.
  // completed_at is stamped when the task is first marked done and cleared
  // if the task is un-completed, so the streak reflects actual completion days.
  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    final db = await dbHelper.database;
    await db.update(
      'tasks',
      {
        'status': newStatus,
        'is_completed': newStatus == 'completed' ? 1 : 0,
        'completed_at': newStatus == 'completed'
            ? DateTime.now().toIso8601String()
            : null,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await dbHelper.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTasks() async {
    final db = await dbHelper.database;
    await db.delete('tasks');
  }

  Future<int> insertSubtask(int taskId, String title) async {
    final db = await dbHelper.database;
    return await db.insert(
      'subtasks',
      {'task_id': taskId, 'title': title, 'is_completed': 0},
    );
  }

  Future<List<Map<String, dynamic>>> fetchSubtasks(int taskId) async {
    final db = await dbHelper.database;
    return await db.query(
      'subtasks',
      columns: ['id', 'task_id', 'title', 'is_completed'],
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> updateSubtask(int subtaskId, String newTitle) async {
    final db = await dbHelper.database;
    return await db.update(
      'subtasks',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [subtaskId],
    );
  }

  // Persists subtask completion state. Called by AppState.toggleSubtaskCompletion.
  Future<int> updateSubtaskStatus(int subtaskId, bool isCompleted) async {
    final db = await dbHelper.database;
    return await db.update(
      'subtasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [subtaskId],
    );
  }

  Future<int> deleteSubtask(int subtaskId) async {
    final db = await dbHelper.database;
    return await db.delete('subtasks', where: 'id = ?', whereArgs: [subtaskId]);
  }
}