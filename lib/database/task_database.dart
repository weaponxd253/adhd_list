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

Future<int> editTask(int id, String newTitle, String newDueDate) async {
  Database db = await dbHelper.database;
  return await db.update(
    'tasks',
    {
      'title': newTitle,
      'due_date': newDueDate,
    },
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<int> insertSubtask(int taskId, String title) async {
  Database db = await dbHelper.database;
  return await db.insert(
    'subtasks',
    {'task_id': taskId, 'title': title, 'is_completed': 0},
  );
}

Future<List<Map<String, dynamic>>> fetchSubtasks(int taskId) async {
  Database db = await dbHelper.database;
  
  print("Fetching subtasks for task ID: $taskId");  //  Debugging log
  
  try {
    final result = await db.query(
      'subtasks',
      columns: ['id', 'task_id', 'title', 'is_completed'],  //  Ensure task_id is included
      where: 'task_id = ?',
      whereArgs: [taskId],
    );

    print("Fetched subtasks: $result");  //  Debugging log
    return result;
  } catch (e) {
    print("Error fetching subtasks: $e");  // Catch error
    return [];
  }
}


Future<int> updateSubtask(int subtaskId, String newTitle) async {
  Database db = await dbHelper.database;
  return await db.update(
    'subtasks',
    {'title': newTitle},
    where: 'id = ?',
    whereArgs: [subtaskId],
  );
}

Future<int> deleteSubtask(int subtaskId) async {
  Database db = await dbHelper.database;
  return await db.delete('subtasks', where: 'id = ?', whereArgs: [subtaskId]);
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
