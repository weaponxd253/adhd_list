import 'dart:io';

import 'package:adhd_list/database/database_helper.dart';
import 'package:adhd_list/database/settings_database.dart';
import 'package:adhd_list/database/task_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('Database schema', () {
    late DatabaseHelper helper;

    setUp(() {
      helper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
    });

    tearDown(() => helper.close());

    test('creates all tables and indexes at version 6', () async {
      final db = await helper.database;
      final objects = await db.query(
        'sqlite_master',
        columns: ['name', 'type'],
        where: 'name NOT LIKE ?',
        whereArgs: ['sqlite_%'],
      );
      final names = {for (final row in objects) row['name'] as String};

      expect(names, containsAll(['tasks', 'subtasks', 'moods', 'settings']));
      expect(
        names,
        containsAll([
          'idx_tasks_due_date',
          'idx_subtasks_task_id',
          'idx_moods_date',
        ]),
      );
      expect(await db.getVersion(), 6);
    });

    test('enforces due dates and foreign keys', () async {
      final db = await helper.database;

      await expectLater(
        db.insert('tasks', {'title': 'Missing due date'}),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert('subtasks', {
          'task_id': 999,
          'title': 'Orphan',
          'is_completed': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('deleting a task cascades to its subtasks', () async {
      final tasks = TaskDatabase(dbHelper: helper);
      final taskId = await tasks.insertTask(
          'Task', DateTime(2026, 6, 24).toIso8601String());
      await tasks.insertSubtask(taskId, 'Step');

      await tasks.deleteTask(taskId);

      expect(await tasks.fetchSubtasks(taskId), isEmpty);
    });

    test('keeps completion columns synchronized', () async {
      final tasks = TaskDatabase(dbHelper: helper);
      final taskId = await tasks.insertTask(
          'Task', DateTime(2026, 6, 24).toIso8601String());

      await tasks.updateTaskStatus(taskId, 'completed');
      var row = (await tasks.fetchTasks()).single;
      expect(row['status'], 'completed');
      expect(row['is_completed'], 1);
      expect(row['completed_at'], isNotNull);

      await tasks.updateTaskStatus(taskId, 'pending');
      row = (await tasks.fetchTasks()).single;
      expect(row['status'], 'pending');
      expect(row['is_completed'], 0);
      expect(row['completed_at'], isNull);
    });

    test('settings use replace semantics', () async {
      final settings = SettingsDatabase(dbHelper: helper);

      await settings.write('theme_mode', 'light');
      await settings.write('theme_mode', 'dark');

      expect(await settings.read('theme_mode'), 'dark');
      final db = await helper.database;
      expect(await db.query('settings'), hasLength(1));
    });

    test('zero-row updates and deletes throw', () async {
      final tasks = TaskDatabase(dbHelper: helper);

      await expectLater(
        tasks.editTask(404, 'Missing', DateTime(2026, 6, 24).toIso8601String()),
        throwsStateError,
      );
      await expectLater(tasks.deleteTask(404), throwsStateError);
    });
  });

  test('version 6 repairs a version 4 database with missing objects', () async {
    final directory = await Directory.systemTemp.createTemp('focusflow_test_');
    final path = '${directory.path}${Platform.pathSeparator}repair.db';
    final oldDb = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              due_date TEXT,
              is_completed INTEGER DEFAULT 0
            )
          ''');
          await db.insert('tasks', {
            'title': 'Legacy',
            'due_date': null,
            'is_completed': 0,
          });
        },
      ),
    );
    await oldDb.close();

    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
      databasePath: path,
    );
    addTearDown(() async {
      await helper.close();
      await databaseFactoryFfi.deleteDatabase(path);
      await directory.delete(recursive: true);
    });

    final db = await helper.database;
    final taskColumns = await db.rawQuery('PRAGMA table_info(tasks)');
    final columnNames = taskColumns.map((row) => row['name']);
    final tables = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['table'],
    );
    final tableNames = tables.map((row) => row['name']);

    expect(columnNames, containsAll(['status', 'completed_at']));
    expect(tableNames, containsAll(['subtasks', 'moods', 'settings']));
    expect((await db.query('tasks')).single['due_date'], isNotNull);
    expect(await db.getVersion(), 6);
  });
}
