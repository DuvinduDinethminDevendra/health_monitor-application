import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/step_record.dart';
import '../models/workout_record.dart';
import '../models/activity.dart';
import '../repositories/step_record_repository.dart';
import '../repositories/workout_record_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/goal_repository.dart';

const _kStepCacheDate  = 'activity_step_cache_date';
const _kStepCacheCount = 'activity_step_cache_count';

class ActivityProvider extends ChangeNotifier {
  final StepRecordRepository _stepRepo = StepRecordRepository();
  final WorkoutRecordRepository _workoutRepo = WorkoutRecordRepository();
  final ActivityRepository _activityRepo = ActivityRepository();

  int liveStepCount = 0;
  int dailyStepGoal = 10000;
  bool isLoading = false;
  String? errorMessage;

  StepRecord? todayStepRecord;
  List<StepRecord> weeklySteps = [];
  List<WorkoutRecord> todaysWorkouts = [];
  List<WorkoutRecord> allWorkouts = [];
  List<Activity> recentActivities = [];

  // Live Workout State
  bool isWorkoutActive = false;
  bool isWorkoutPaused = false;
  int workoutElapsedSeconds = 0;
  Timer? _workoutTimer;
  String currentWorkoutType = 'Walking';

  double get stepProgress => dailyStepGoal > 0 ? liveStepCount / dailyStepGoal : 0;
  int get remainingSteps => (dailyStepGoal - liveStepCount).clamp(0, dailyStepGoal);
  
  double get todayDistanceKm => (liveStepCount * 0.000762).clamp(0.0, 100.0);
  int get todayCalories => (liveStepCount * 0.04).toInt() + todaysWorkouts.fold(0, (sum, w) => sum + (w.caloriesBurned ?? 0));
  int get todayWorkoutDuration => todaysWorkouts.fold(0, (sum, w) => sum + w.durationMins);
  int get todayActiveMinutes => (liveStepCount / 100).floor() + todayWorkoutDuration;

  String get syncStatusText => "Up to date"; // Simplified for now

  String get smartInsightText {
    if (liveStepCount >= dailyStepGoal) {
      return "Amazing! You've reached your daily step goal. Keep up the great work!";
    } else if (remainingSteps > 0 && remainingSteps < 2000) {
      return "You are so close! Only $remainingSteps steps left to crush your daily goal.";
    } else if (liveStepCount == 0) {
      return "Ready to move? Start your day with a quick walk to energize yourself.";
    } else {
      return "You're on your way! Every step counts towards a healthier you.";
    }
  }

  Future<void> loadData(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _runCatchUpCheck(userId);

      final today = _todayString();
      todayStepRecord = await _stepRepo.getStepRecordByDate(userId, today);

      final prefs = await SharedPreferences.getInstance();
      final cachedDate  = prefs.getString(_kStepCacheDate) ?? '';
      final cachedSteps = prefs.getInt(_kStepCacheCount)   ?? 0;
      liveStepCount = (cachedDate == today) ? cachedSteps : 0;

      weeklySteps = await _stepRepo.getLast7DaysSteps(userId);
      todaysWorkouts = await _workoutRepo.getTodaysWorkouts(userId, today);
      allWorkouts = await _workoutRepo.getWorkoutsByUser(userId);
      
      // Load general activities for history
      recentActivities = await _activityRepo.getActivitiesByUser(userId);
      
    } catch (e) {
      errorMessage = 'Failed to load activity data: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshActivityData(String userId) async {
    await loadData(userId);
  }

  Future<void> _runCatchUpCheck(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate  = prefs.getString(_kStepCacheDate);
    final cachedSteps = prefs.getInt(_kStepCacheCount) ?? 0;

    if (cachedDate == null) return;
    final today = _todayString();
    if (cachedDate == today) return;

    try {
      final missedRecord = StepRecord(
        userId: userId,
        date: cachedDate,
        stepCount: cachedSteps,
        goal: dailyStepGoal,
      );
      await _stepRepo.upsertStepRecord(missedRecord);
    } catch (e) {
      debugPrint('[CatchUp] Failed: $e');
    }

    await prefs.setString(_kStepCacheDate,  today);
    await prefs.setInt(_kStepCacheCount, 0);
    liveStepCount = 0;
  }

  Future<void> updateLiveSteps(int steps, String userId) async {
    liveStepCount = steps;
    final today = _todayString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStepCacheDate, today);
    await prefs.setInt(_kStepCacheCount, steps);

    // ── Persist to DB so the weekly chart always has today's real data ──────
    // upsertStepRecord uses ConflictAlgorithm.replace, so this is safe to
    // call on every step event — it just overwrites today's row each time.
    try {
      await _stepRepo.upsertStepRecord(StepRecord(
        userId:    userId,
        date:      today,
        stepCount: steps,
        goal:      dailyStepGoal,
      ));
    } catch (_) {
      // Non-critical — live count is already updated in RAM
    }

    notifyListeners();
  }

  Future<void> saveTodaySteps(String userId) async {
    try {
      final today = _todayString();
      final record = StepRecord(
        userId: userId,
        date: today,
        stepCount: liveStepCount,
        goal: dailyStepGoal,
      );
      await _stepRepo.upsertStepRecord(record);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStepCacheDate,  today);
      await prefs.setInt(_kStepCacheCount, 0);

      liveStepCount = 0;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to save steps: ${e.toString()}';
      notifyListeners();
    }
  }

  // Live Workout Tracking
  void startWorkout(String type) {
    currentWorkoutType = type;
    isWorkoutActive = true;
    isWorkoutPaused = false;
    workoutElapsedSeconds = 0;
    
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isWorkoutPaused) {
        workoutElapsedSeconds++;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void pauseWorkout() {
    isWorkoutPaused = true;
    notifyListeners();
  }

  void resumeWorkout() {
    isWorkoutPaused = false;
    notifyListeners();
  }

  void stopWorkout() {
    _workoutTimer?.cancel();
    isWorkoutActive = false;
    isWorkoutPaused = false;
    notifyListeners();
  }

  Future<void> finishWorkout(String userId) async {
    stopWorkout();
    
    int minutes = (workoutElapsedSeconds / 60).ceil();
    if (minutes == 0) minutes = 1;

    final workout = WorkoutRecord(
      userId: userId,
      workoutType: currentWorkoutType,
      durationMins: minutes,
      caloriesBurned: (minutes * 8), // rough estimate
      loggedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
    
    await addWorkout(workout);
    
    // Also save to generic activities for universal sync
    await logManualActivity(userId.toString(), currentWorkoutType, minutes.toDouble(), minutes, DateTime.now());
  }

  Future<void> addWorkout(WorkoutRecord workout) async {
    try {
      await _workoutRepo.insertWorkout(workout);
      final today = _todayString();
      todaysWorkouts = await _workoutRepo.getTodaysWorkouts(workout.userId, today);
      allWorkouts = await _workoutRepo.getWorkoutsByUser(workout.userId);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to log workout: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> logManualActivity(String userId, String type, double value, int duration, DateTime date) async {
    try {
      final activity = Activity(
        userId: userId,
        type: type,
        value: value,
        date: DateFormat('yyyy-MM-dd').format(date),
        duration: duration,
      );
      
      await _activityRepo.insertActivity(activity);
      
      // Goal Sync
      final goalRepo = GoalRepository();
      final goals = await goalRepo.getGoalsByUser(userId);
      for (var goal in goals) {
        if (goal.baseType == activity.type.toLowerCase()) {
           bool isDaily = goal.category.contains('(Daily)');
           double newProgress;
           if (isDaily) {
              final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final acts = await _activityRepo.getActivitiesByDateRange(userId, dateStr, dateStr);
              newProgress = acts.where((a) => a.type.toLowerCase() == goal.baseType).fold(0.0, (sum, a) => sum + a.value);
           } else {
              newProgress = goal.currentValue + activity.value;
           }
           await goalRepo.updateProgress(goal.id!, newProgress);
           if (newProgress >= goal.targetValue && !goal.isCompleted) {
              await goalRepo.markCompleted(goal.id!);
           }
        }
      }
      
      // Reload recent
      recentActivities = await _activityRepo.getActivitiesByUser(userId);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to log activity: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteWorkout(int id, String userId) async {
    try {
      await _workoutRepo.deleteWorkout(id);
      final today = _todayString();
      todaysWorkouts = await _workoutRepo.getTodaysWorkouts(userId, today);
      allWorkouts = await _workoutRepo.getWorkoutsByUser(userId);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to delete workout: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteActivity(int id, String userId) async {
    try {
      await _activityRepo.deleteActivity(id);
      recentActivities = await _activityRepo.getActivitiesByUser(userId);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to delete activity: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  String _todayString() => DateFormat('yyyy-MM-dd').format(DateTime.now());
  
  @override
  void dispose() {
    _workoutTimer?.cancel();
    super.dispose();
  }
}
