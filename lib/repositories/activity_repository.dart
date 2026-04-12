import '../database/database_helper.dart';
import '../models/activity.dart';

class ActivityRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertActivity(Activity activity) async {
    final db = await _dbHelper.database;
    return await db.insert('activities', activity.toMap());
  }

  Future<List<Activity>> getActivitiesByUser(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'activities',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Activity.fromMap(map)).toList();
  }

  Future<List<Activity>> getActivitiesByDate(int userId, String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'activities',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      orderBy: 'id DESC',
    );
    return maps.map((map) => Activity.fromMap(map)).toList();
  }

  Future<List<Activity>> getActivitiesByDateRange(
      int userId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'activities',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((map) => Activity.fromMap(map)).toList();
  }

  Future<int> updateActivity(Activity activity) async {
    final db = await _dbHelper.database;
    return await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<int> deleteActivity(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
