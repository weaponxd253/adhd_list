import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class TaskDatabase {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertTask(String title, String dueDate) async {
    final db = await dbHelper.database;
    return await db.insert(
      'tasks',
      {'title': title, 'due_date': dueDate, 'is_completed': 0, 'status': 'pending'},
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

  // Keeps is_completed and status in sync so reads after restart are correct.
  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    final db = await dbHelper.database;
    await db.update(
      'tasks',
      {
        'status': newStatus,
        'is_completed': newStatus == 'completed' ? 1 : 0,
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

  Future<int> deleteSubtask(int subtaskId) async {
    final db = await dbHelper.database;
    return await db.delete('subtasks', where: 'id = ?', whereArgs: [subtaskId]);
  }
}
