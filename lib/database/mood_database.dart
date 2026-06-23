import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../repositories/repositories.dart';

// MoodDatabase is now a thin facade over DatabaseHelper.
// All mood data lives in focusflow.db alongside tasks and subtasks.
class MoodDatabase implements MoodRepository {
  static final MoodDatabase _instance = MoodDatabase();
  static MoodDatabase get instance => _instance;

  MoodDatabase({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<Database> get _db async => _dbHelper.database;

  @override
  Future<Map<String, dynamic>?> fetchLastMood() async {
    final db = await _db;
    final results = await db.query(
      'moods',
      orderBy: 'date DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<int> insertMood(String mood, String emoji) async {
    final db = await _db;
    return await db.insert('moods', {
      'mood': mood,
      'emoji': emoji,
      'date': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMoods() async {
    final db = await _db;
    return await db.query('moods', orderBy: 'date DESC');
  }

  @override
  Future<void> clearMoods() async {
    final db = await _db;
    await db.delete('moods');
  }
}
