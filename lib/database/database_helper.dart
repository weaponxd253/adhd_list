import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'focusflow.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // onOpen runs on every launch after onCreate/onUpgrade.
      // This is the only reliable way to backfill a table that was missing
      // from all prior migration paths — version-based migrations are skipped
      // once the device DB is already at that version number.
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    // Ensure subtasks exists regardless of version history.
    // IF NOT EXISTS makes this a no-op on any install that already has it.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subtasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // Also ensure completed_at exists — ALTER TABLE ignores errors if the
    // column is already present by wrapping in a try/catch at the Dart level.
    try {
      await db.execute(
          "ALTER TABLE tasks ADD COLUMN completed_at TEXT");
    } catch (_) {
      // Column already exists — safe to ignore.
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE tasks ADD COLUMN status TEXT DEFAULT 'pending'");
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS moods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mood TEXT NOT NULL,
          emoji TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
          "ALTER TABLE tasks ADD COLUMN completed_at TEXT");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        due_date TEXT,
        is_completed INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        completed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE subtasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE moods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood TEXT NOT NULL,
        emoji TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }
}