import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/health_log.dart';

class HealthLogRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertLog(HealthLog log) async {
    final db = await _dbHelper.database;
    return await db.insert('health_logs', log.toMap());
  }

  Future<void> upsertLog(HealthLog log) async {
    final db = await _dbHelper.database;
    await db.insert('health_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Alias for UI expectation
  Future<int> insertHealthLog(HealthLog log) async {
    return await insertLog(log);
  }

  Future<int> updateHealthLog(HealthLog log) async {
    final db = await _dbHelper.database;
    return await db.update(
      'health_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<List<HealthLog>> getLogsByUser(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => HealthLog.fromMap(maps[i]));
  }

  // Alias for UI expectation
  Future<List<HealthLog>> getHealthLogsByUser(String userId) async {
    return await getLogsByUser(userId);
  }

  Future<HealthLog?> getLatestLog(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return HealthLog.fromMap(maps.first);
  }

  Future<List<HealthLog>> getUnsyncedLogs(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_logs',
      where: 'user_id = ? AND sync_status = 0',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => HealthLog.fromMap(maps[i]));
  }

  Future<void> updateSyncStatus(int id, int status) async {
    final db = await _dbHelper.database;
    await db.update(
      'health_logs',
      {'sync_status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHealthLog(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'health_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<HealthLog>> getLogsByDateRange(
      String userId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_logs',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) => HealthLog.fromMap(maps[i]));
  }
}
