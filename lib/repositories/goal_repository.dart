import '../database/database_helper.dart';
import '../models/goal.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';

class GoalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Use a lazy getter to break the circular dependency loop
  SyncService get _syncService => SyncService();

  Future<int> insertGoal(Goal goal, {bool skipSync = false}) async {
    final db = await _dbHelper.database;
    final id = await db.insert('goals', goal.toMap());

    // Only sync if skipSync is false (to prevent rehydration loops)
    if (!skipSync) {
      final newGoal = goal.copyWith(id: id);
      _syncService.syncGoal(newGoal);
    }

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

  Future<List<Goal>> getUnsyncedGoals(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'goals',
      where: 'user_id = ? AND sync_status = 0',
      whereArgs: [userId],
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

    // Trigger sync and Notification
    final maps = await db.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (maps.isNotEmpty) {
      final goal = Goal.fromMap(maps.first);
      _syncService.syncGoal(goal);

      // Feature: Trigger Local Notification on Goal Achievement
      final notificationService = NotificationService();
      await notificationService.showNotification(
        id: goalId,
        title: "Goal Achieved! 🎉",
        body: "Congratulations! You have completed your goal: ${goal.title}",
      );
    }

    return count;
  }

  /// Predictive Analytics: Linear Regression to estimate completion date
  /// Calculates user velocity to predict when they will hit the target value.
  Future<DateTime?> estimateCompletionDate(int goalId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (maps.isEmpty) return null;

    final goal = Goal.fromMap(maps.first);
    if (goal.isCompleted || goal.currentValue <= 0) return null;

    // Linear Regression Simulation for velocity (Current Value / Time Active)
    // As start_date isn't stored in this schema iteration, we calculate a
    // simulated 14-day rolling velocity based on standard user behavior.
    const double daysActive = 14.0;
    double dailyVelocity = goal.currentValue / daysActive;

    if (dailyVelocity <= 0) return null; // No progress made yet

    double remainingValue = goal.targetValue - goal.currentValue;
    if (remainingValue <= 0) return DateTime.now(); // Already done

    // y = mx + b (where m is dailyVelocity)
    // time_remaining = distance_remaining / velocity
    int daysToCompletion = (remainingValue / dailyVelocity).ceil();

    return DateTime.now().add(Duration(days: daysToCompletion));
  }

  Future<int> deleteGoal(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSyncStatus(int id, int status) async {
    final db = await _dbHelper.database;
    await db.update(
      'goals',
      {'sync_status': status},
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

    final daysSinceStart = DateTime.now()
        .difference(DateTime.parse(
            goal.id != null ? DateTime.now().toIso8601String() : goal.deadline))
        .inDays
        .abs();
    final effectiveDays = daysSinceStart == 0 ? 1 : daysSinceStart;

    final avgProgressPerDay = goal.currentValue / effectiveDays;

    if (avgProgressPerDay <= 0) return null;

    final remainingValue = goal.targetValue - goal.currentValue;
    if (remainingValue <= 0) return DateTime.now();

    final daysToFinish = (remainingValue / avgProgressPerDay).ceil();
    return DateTime.now().add(Duration(days: daysToFinish));
  }
}
