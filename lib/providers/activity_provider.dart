import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/step_record.dart';
import '../models/workout_record.dart';
import '../repositories/step_record_repository.dart';
import '../repositories/workout_record_repository.dart';

// ─────────────────────────────────────────────────────────
// SharedPreferences Keys (scoped to avoid name collisions)
// ─────────────────────────────────────────────────────────
const _kStepCacheDate  = 'activity_step_cache_date';   // 'yyyy-MM-dd'
const _kStepCacheCount = 'activity_step_cache_count';  // int

class ActivityProvider extends ChangeNotifier {
  // ── Repositories ──────────────────────────────────────
  final StepRecordRepository   _stepRepo    = StepRecordRepository();
  final WorkoutRecordRepository _workoutRepo = WorkoutRecordRepository();

  // ── Live State ────────────────────────────────────────
  int  liveStepCount      = 0;
  int  dailyStepGoal      = 10000;
  bool isLoading          = false;
  String? errorMessage;

  // ── Persisted Data ────────────────────────────────────
  StepRecord?          todayStepRecord;
  List<StepRecord>     weeklySteps    = [];
  List<WorkoutRecord>  todaysWorkouts = [];
  List<WorkoutRecord>  allWorkouts    = [];

  // ── Computed ──────────────────────────────────────────
  /// Progress ratio 0.0 → 1.0 (can exceed 1.0 if goal is surpassed).
  double get stepProgress  => dailyStepGoal > 0 ? liveStepCount / dailyStepGoal : 0;
  int    get remainingSteps => (dailyStepGoal - liveStepCount).clamp(0, dailyStepGoal);
  int    get totalWorkoutMinutesToday =>
      todaysWorkouts.fold(0, (sum, w) => sum + w.durationMins);

  // ─────────────────────────────────────────────────────
  // PUBLIC: initialise everything for the logged-in user
  // ─────────────────────────────────────────────────────
  Future<void> loadData(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Run catch-up FIRST — before reading today's record.
      await _runCatchUpCheck(userId);

      // 2. Load today's saved step record (may have just been written above).
      final today = _todayString();
      todayStepRecord = await _stepRepo.getStepRecordByDate(userId, today);

      // 3. Restore live step count from cache (survives hot-restart).
      final prefs = await SharedPreferences.getInstance();
      final cachedDate  = prefs.getString(_kStepCacheDate) ?? '';
      final cachedSteps = prefs.getInt(_kStepCacheCount)   ?? 0;
      liveStepCount = (cachedDate == today) ? cachedSteps : 0;

      // 4. Load the rest of the UI data.
      weeklySteps    = await _stepRepo.getLast7DaysSteps(userId);
      todaysWorkouts = await _workoutRepo.getTodaysWorkouts(userId, today);
      allWorkouts    = await _workoutRepo.getWorkoutsByUser(userId);
    } catch (e) {
      errorMessage = 'Failed to load activity data: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────
  // PIECE 1 — CATCH-UP CHECK
  // Called once at app startup (inside loadData).
  // Handles the scenario where the device was powered off
  // at midnight and the background service never ran.
  // ─────────────────────────────────────────────────────
  Future<void> _runCatchUpCheck(int userId) async {
    final prefs = await SharedPreferences.getInstance();

    final cachedDate  = prefs.getString(_kStepCacheDate);
    final cachedSteps = prefs.getInt(_kStepCacheCount) ?? 0;

    // Nothing cached yet — first ever launch, nothing to recover.
    if (cachedDate == null) return;

    final today = _todayString();

    if (cachedDate == today) {
      // ✅ Dates match — background service ran correctly, nothing to do.
      return;
    }

    // ⚠️ Dates differ — the midnight background task was MISSED.
    // The user's step data for `cachedDate` was never saved to SQLite.
    // Retroactively save it now.
    debugPrint('[CatchUp] Missed save detected. '
        'Saving $cachedSteps steps for $cachedDate.');

    try {
      final missedRecord = StepRecord(
        userId:    userId,
        date:      cachedDate,          // The PAST date, not today
        stepCount: cachedSteps,
        goal:      dailyStepGoal,
      );

      // upsertTodaySteps handles INSERT OR REPLACE to avoid duplicates.
      await _stepRepo.upsertStepRecord(missedRecord);

      debugPrint('[CatchUp] Successfully saved missed step record.');
    } catch (e) {
      debugPrint('[CatchUp] Failed to save missed record: $e');
    }

    // Reset the cache for the new day.
    await prefs.setString(_kStepCacheDate,  today);
    await prefs.setInt   (_kStepCacheCount, 0);
    liveStepCount = 0;
    // notifyListeners() is NOT called here — caller (loadData) will call it.
  }

  // ─────────────────────────────────────────────────────
  // PIECE 2 — CONTINUOUS CACHING
  // Called by PedometerService every time the hardware
  // sensor fires a new step count event.
  // ─────────────────────────────────────────────────────
  Future<void> updateLiveSteps(int steps, int userId) async {
    liveStepCount = steps;

    // Cache to SharedPreferences immediately so data survives:
    //   - App being killed
    //   - Device reboot
    //   - Missed midnight background task
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStepCacheDate,  _todayString());
    await prefs.setInt   (_kStepCacheCount, steps);

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  // Manual save — triggered by midnight background service
  // OR by the "Simulate Midnight Reset" debug button.
  // ─────────────────────────────────────────────────────
  Future<void> saveTodaySteps(int userId) async {
    try {
      final today = _todayString();
      final record = StepRecord(
        userId:    userId,
        date:      today,
        stepCount: liveStepCount,
        goal:      dailyStepGoal,
      );
      await _stepRepo.upsertStepRecord(record);

      // Reset cache for the new day.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStepCacheDate,  today);
      await prefs.setInt   (_kStepCacheCount, 0);

      liveStepCount = 0;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to save step record: ${e.toString()}';
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────
  // Workout CRUD
  // ─────────────────────────────────────────────────────
  Future<void> addWorkout(WorkoutRecord workout) async {
    try {
      await _workoutRepo.insertWorkout(workout);
      final today = _todayString();
      todaysWorkouts = await _workoutRepo.getTodaysWorkouts(workout.userId, today);
      allWorkouts    = await _workoutRepo.getWorkoutsByUser(workout.userId);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to log workout: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteWorkout(int id, int userId) async {
    try {
      await _workoutRepo.deleteWorkout(id);
      final today = _todayString();
      todaysWorkouts = await _workoutRepo.getTodaysWorkouts(userId, today);
      allWorkouts    = await _workoutRepo.getWorkoutsByUser(userId);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to delete workout: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> setGoal(int newGoal) async {
    dailyStepGoal = newGoal;
    notifyListeners();
  }

  void setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────
  String _todayString() => DateFormat('yyyy-MM-dd').format(DateTime.now());
}
