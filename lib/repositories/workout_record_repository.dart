import '../database/database_helper.dart';
import '../models/workout_record.dart';

class WorkoutRecordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertWorkout(WorkoutRecord workout) async {
    final db = await _dbHelper.database;
    return await db.insert('workout_records', workout.toMap());
  }

  Future<List<WorkoutRecord>> getWorkoutsByUser(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at DESC',
    );
    return maps.map((map) => WorkoutRecord.fromMap(map)).toList();
  }

  Future<List<WorkoutRecord>> getTodaysWorkouts(String userId, String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_records',
      where: 'user_id = ? AND logged_at LIKE ?',
      whereArgs: [userId, '$date%'],
      orderBy: 'logged_at DESC',
    );
    return maps.map((map) => WorkoutRecord.fromMap(map)).toList();
  }

  Future<List<WorkoutRecord>> getWorkoutsByDateRange(String userId, String start, String end) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_records',
      where: 'user_id = ? AND logged_at >= ? AND logged_at <= ?',
      whereArgs: [userId, start, end],
      orderBy: 'logged_at DESC',
    );
    return maps.map((map) => WorkoutRecord.fromMap(map)).toList();
  }

  Future<void> updateWorkout(WorkoutRecord workout) async {
    final db = await _dbHelper.database;
    await db.update(
      'workout_records',
      workout.toMap(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }

  Future<void> deleteWorkout(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'workout_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
