import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

class SettingsDatabase {
  final dbHelper = DatabaseHelper.instance;

  Future<String?> read(String key) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> write(String key, String value) async {
    final db = await dbHelper.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
