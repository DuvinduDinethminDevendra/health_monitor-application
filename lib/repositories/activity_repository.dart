import '../database/database_helper.dart';
import '../models/activity.dart';
import '../services/sync_service.dart';

class ActivityRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();

  Future<int> insertActivity(Activity activity) async {
    final db = await _dbHelper.database;
    final id = await db.insert('activities', activity.toMap());
    
    // Sync to Cloud
    final newActivity = activity.copyWith(id: id);
    _syncService.syncActivity(newActivity);
    
    return id;
  }

  Future<List<Activity>> getActivitiesByUser(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'activities',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Activity.fromMap(map)).toList();
  }

  Future<List<Activity>> getActivitiesByDate(String userId, String date) async {
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
      String userId, String startDate, String endDate) async {
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
    final count = await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
    
    _syncService.syncActivity(activity);
    
    return count;
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
