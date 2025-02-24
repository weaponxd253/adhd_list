import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MoodDatabase {
  // Singleton instance
  static final MoodDatabase _instance = MoodDatabase._privateConstructor();
  static MoodDatabase get instance => _instance; // This line fixes the error

  static Database? _database;

  MoodDatabase._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'moods.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE moods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mood TEXT NOT NULL,
            emoji TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertMood(String mood, String emoji) async {
    Database db = await database;
    String date = DateTime.now().toIso8601String();
    return await db.insert('moods', {'mood': mood, 'emoji': emoji, 'date': date});
  }

  Future<List<Map<String, dynamic>>> fetchMoods() async {
    Database db = await database;
    return await db.query('moods', orderBy: 'date DESC');
  }
}
