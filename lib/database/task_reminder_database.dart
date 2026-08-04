import 'package:sqflite/sqflite.dart';

import '../repositories/repositories.dart';
import 'database_helper.dart';

class TaskReminderDatabase implements TaskReminderRepository {
  TaskReminderDatabase({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper dbHelper;

  @override
  Future<void> clearTaskReminders() async {
    final db = await dbHelper.database;
    await db.delete('task_reminders');
  }

  @override
  Future<void> deleteTaskReminder(int taskId) async {
    final db = await dbHelper.database;
    await db.delete(
      'task_reminders',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchTaskReminder(int taskId) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'task_reminders',
      where: 'task_id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTaskReminders() async {
    final db = await dbHelper.database;
    return db.query('task_reminders', orderBy: 'scheduled_at ASC');
  }

  @override
  Future<void> upsertTaskReminder({
    required int taskId,
    required String style,
    required String scheduledAt,
    bool enabled = true,
  }) async {
    final db = await dbHelper.database;
    await db.insert(
      'task_reminders',
      {
        'task_id': taskId,
        'style': style,
        'scheduled_at': scheduledAt,
        'enabled': enabled ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
