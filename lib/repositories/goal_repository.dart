import '../database/database_helper.dart';
import '../models/goal.dart';

class GoalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertGoal(Goal goal) async {
    final db = await _dbHelper.database;
    return await db.insert('goals', goal.toMap());
  }

  Future<List<Goal>> getGoalsByUser(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'deadline ASC',
    );
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  Future<List<Goal>> getActiveGoals(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'goals',
      where: 'user_id = ? AND is_completed = 0',
      whereArgs: [userId],
      orderBy: 'deadline ASC',
    );
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await _dbHelper.database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> updateProgress(int goalId, double newValue) async {
    final db = await _dbHelper.database;
    return await db.update(
      'goals',
      {'current_value': newValue},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<int> markCompleted(int goalId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'goals',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
