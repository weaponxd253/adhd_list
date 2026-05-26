import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

// MoodDatabase is now a thin facade over DatabaseHelper.
// All mood data lives in focusflow.db alongside tasks and subtasks.
class MoodDatabase {
  static final MoodDatabase _instance = MoodDatabase._privateConstructor();
  static MoodDatabase get instance => _instance;

  MoodDatabase._privateConstructor();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<Map<String, dynamic>?> fetchLastMood() async {
    final db = await _db;
    final results = await db.query(
      'moods',
      orderBy: 'date DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertMood(String mood, String emoji) async {
    final db = await _db;
    return await db.insert('moods', {
      'mood': mood,
      'emoji': emoji,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchMoods() async {
    final db = await _db;
    return await db.query('moods', orderBy: 'date DESC');
  }

  Future<void> clearMoods() async {
    final db = await _db;
    await db.delete('moods');
  }
}
