import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _schemaVersion = 11;
  static final DatabaseHelper instance = DatabaseHelper._();

  DatabaseHelper._({
    DatabaseFactory? databaseFactory,
    String? databasePath,
  })  : _databaseFactory = databaseFactory ?? databaseFactorySqflitePlugin,
        _databasePath = databasePath;

  factory DatabaseHelper.forTesting({
    required DatabaseFactory databaseFactory,
    required String databasePath,
  }) {
    return DatabaseHelper._(
      databaseFactory: databaseFactory,
      databasePath: databasePath,
    );
  }

  final DatabaseFactory _databaseFactory;
  final String? _databasePath;
  Future<Database>? _databaseFuture;

  Future<Database> get database => _databaseFuture ??= _initDatabase();

  Future<Database> _initDatabase() async {
    final path = _databasePath ??
        join(await _databaseFactory.getDatabasesPath(), 'focusflow.db');
    return _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> close() async {
    final future = _databaseFuture;
    if (future == null) return;
    await (await future).close();
    _databaseFuture = null;
  }

  Future<void> _createSubtasksTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subtasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        estimated_minutes INTEGER,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createMoodsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS moods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood TEXT NOT NULL,
        emoji TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureColumn(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $definition');
    }
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subtasks_task_id ON subtasks(task_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_moods_date ON moods(date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_timer_sessions_ended_at '
      'ON timer_sessions(ended_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_reminders_scheduled_at '
      'ON task_reminders(scheduled_at)',
    );
  }

  Future<void> _createSettingsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTimerSessionsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS timer_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        completed INTEGER DEFAULT 1,
        task_id INTEGER,
        subtask_id INTEGER,
        target_type TEXT NOT NULL DEFAULT 'none',
        target_title_snapshot TEXT,
        outcome TEXT
      )
    ''');
  }

  Future<void> _createTaskRemindersTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_reminders (
        task_id INTEGER PRIMARY KEY,
        style TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        enabled INTEGER DEFAULT 1,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // This is a repair migration as well as a normal upgrade. Earlier
    // releases could report the latest version while still missing a table or
    // column, so inspect the schema before altering it.
    await _ensureColumn(
      db,
      'tasks',
      'status',
      "status TEXT DEFAULT 'pending'",
    );
    await _ensureColumn(db, 'tasks', 'completed_at', 'completed_at TEXT');
    await _ensureColumn(db, 'tasks', 'friction', 'friction TEXT');
    await _ensureColumn(db, 'tasks', 'energy_level', 'energy_level TEXT');
    await _ensureColumn(db, 'tasks', 'time_estimate', 'time_estimate TEXT');
    await _ensureColumn(db, 'tasks', 'anxiety_level', 'anxiety_level TEXT');
    await _ensureColumn(
      db,
      'tasks',
      'estimated_minutes',
      'estimated_minutes INTEGER',
    );
    await _createTimerSessionsTable(db);
    await _ensureColumn(db, 'timer_sessions', 'task_id', 'task_id INTEGER');
    await _ensureColumn(
      db,
      'timer_sessions',
      'subtask_id',
      'subtask_id INTEGER',
    );
    await _ensureColumn(
      db,
      'timer_sessions',
      'target_type',
      "target_type TEXT NOT NULL DEFAULT 'none'",
    );
    await _ensureColumn(
      db,
      'timer_sessions',
      'target_title_snapshot',
      'target_title_snapshot TEXT',
    );
    await _ensureColumn(db, 'timer_sessions', 'outcome', 'outcome TEXT');
    await db.update(
      'tasks',
      {
        'due_date':
            DateTime.now().add(const Duration(days: 30)).toIso8601String()
      },
      where: 'due_date IS NULL',
    );
    await _createSubtasksTable(db);
    await _ensureColumn(
      db,
      'subtasks',
      'estimated_minutes',
      'estimated_minutes INTEGER',
    );
    await _createMoodsTable(db);
    await _createSettingsTable(db);
    await _createTaskRemindersTable(db);
    await _createIndexes(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        due_date TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        completed_at TEXT,
        friction TEXT,
        energy_level TEXT,
        time_estimate TEXT,
        anxiety_level TEXT,
        estimated_minutes INTEGER
      )
    ''');

    await _createSubtasksTable(db);
    await _createMoodsTable(db);
    await _createSettingsTable(db);
    await _createTimerSessionsTable(db);
    await _createTaskRemindersTable(db);
    await _createIndexes(db);
  }
}
