import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class TaskDatabase {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertTask(String title, String dueDate) async {
    Database db = await dbHelper.database;
    return await db.insert(
      'tasks',
      {'title': title, 'due_date': dueDate, 'is_completed': 0},
    );
  }

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    Database db = await dbHelper.database;
    return await db.query('tasks');
  }

  Future<int> updateTask(int id, int isCompleted) async {
    Database db = await dbHelper.database;
    return await db.update(
      'tasks',
      {'is_completed': isCompleted},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTaskStatus(int taskId, String newStatus) async {
  final db = await dbHelper.database;
  await db.update(
    'tasks',  // Make sure this matches your database table name
    {'status': newStatus},
    where: 'id = ?',
    whereArgs: [taskId],
  );
}


  Future<int> deleteTask(int id) async {
    Database db = await dbHelper.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
