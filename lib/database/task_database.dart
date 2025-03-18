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

  Future<void> updateTaskCompletion(int taskId, bool isCompleted) async {
  final db = await dbHelper.database;
  await db.update(
    'tasks',
    {'is_completed': isCompleted ? 1 : 0}, // Update completion status
    where: 'id = ?',
    whereArgs: [taskId],
  );
}


Future<void> updateTaskStatus(int taskId, String newStatus) async {
  final db = await dbHelper.database;
  await db.update(
    'tasks',  
    {'status': newStatus}, // Update the status instead of isCompleted
    where: 'id = ?',
    whereArgs: [taskId],
  );
}


Future<void> clearTasks() async {
  final db = await dbHelper.database; // Use dbHelper.database to access the DB
  await db.delete('tasks'); // Assuming the table name is 'tasks'
}






  Future<int> deleteTask(int id) async {
    Database db = await dbHelper.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
