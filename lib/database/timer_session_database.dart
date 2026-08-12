import 'database_helper.dart';
import '../repositories/repositories.dart';

class TimerSessionDatabase implements TimerSessionRepository {
  TimerSessionDatabase({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper dbHelper;

  @override
  Future<int> insertSession(Map<String, Object?> session) async {
    final db = await dbHelper.database;
    return db.insert('timer_sessions', session);
  }

  @override
  Future<void> updateSessionOutcome(int sessionId, String outcome) async {
    final db = await dbHelper.database;
    final count = await db.update(
      'timer_sessions',
      {'outcome': outcome},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    if (count == 0) {
      throw StateError('Updating timer session $sessionId did not match.');
    }
  }

  @override
  Future<List<Map<String, Object?>>> fetchSessions({int limit = 60}) async {
    final db = await dbHelper.database;
    return db.query(
      'timer_sessions',
      orderBy: 'ended_at DESC',
      limit: limit,
    );
  }

  @override
  Future<void> clearSessions() async {
    final db = await dbHelper.database;
    await db.delete('timer_sessions');
  }
}
