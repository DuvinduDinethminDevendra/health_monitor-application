import '../database/database_helper.dart';
import '../models/health_log.dart';

class HealthLogRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertHealthLog(HealthLog log) async {
    final db = await _dbHelper.database;
    return await db.insert('health_logs', log.toMap());
  }

  Future<List<HealthLog>> getHealthLogsByUser(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'health_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => HealthLog.fromMap(map)).toList();
  }

  Future<HealthLog?> getLatestLog(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'health_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HealthLog.fromMap(maps.first);
  }

  Future<List<HealthLog>> getLogsByDateRange(
      int userId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'health_logs',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((map) => HealthLog.fromMap(map)).toList();
  }

  Future<int> deleteHealthLog(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'health_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
