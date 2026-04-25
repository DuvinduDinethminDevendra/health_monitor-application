import '../database/database_helper.dart';
import '../models/goal.dart';
import '../services/sync_service.dart';

class GoalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();

  Future<int> insertGoal(Goal goal) async {
    final db = await _dbHelper.database;
    final id = await db.insert('goals', goal.toMap());
    
    // Trigger Async Sync
    final newGoal = goal.copyWith(id: id);
    _syncService.syncGoal(newGoal);
    
    return id;
  }


  Future<List<Goal>> getGoalsByUser(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'deadline ASC',
    );
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  Future<List<Goal>> getActiveGoals(String userId) async {
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
    final count = await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    _syncService.syncGoal(goal);
    return count;
  }

  Future<int> updateProgress(int goalId, double newValue) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      'goals',
      {'current_value': newValue},
      where: 'id = ?',
      whereArgs: [goalId],
    );
    
    // Trigger sync for the updated goal
    final maps = await db.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (maps.isNotEmpty) {
      _syncService.syncGoal(Goal.fromMap(maps.first));
    }
    
    return count;
  }

  Future<int> markCompleted(int goalId) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      'goals',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [goalId],
    );

    // Trigger sync
    final maps = await db.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (maps.isNotEmpty) {
      _syncService.syncGoal(Goal.fromMap(maps.first));
    }

    return count;
  }


  Future<int> deleteGoal(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- SMART LOGIC ---

  /// Calculates the expected completion date based on average progress per day.
  Future<DateTime?> calculateExpectedCompletionDate(Goal goal) async {
    if (goal.currentValue <= 0) return null;

    final db = await _dbHelper.database;
    
    // 1. Get user's recent activity relevant to this goal type (mocked logic for now)
    // In a full implementation, we would filter by activity type.
    
    final daysSinceStart = DateTime.now().difference(DateTime.parse(goal.id != null ? DateTime.now().toIso8601String() : goal.deadline)).inDays.abs();
    final effectiveDays = daysSinceStart == 0 ? 1 : daysSinceStart;
    
    final avgProgressPerDay = goal.currentValue / effectiveDays;
    
    if (avgProgressPerDay <= 0) return null;
    
    final remainingValue = goal.targetValue - goal.currentValue;
    if (remainingValue <= 0) return DateTime.now();
    
    final daysToFinish = (remainingValue / avgProgressPerDay).ceil();
    return DateTime.now().add(Duration(days: daysToFinish));
  }
}

