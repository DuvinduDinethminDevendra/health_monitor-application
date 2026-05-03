import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/goal_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/health_log_repository.dart';
import '../repositories/step_record_repository.dart';
import '../models/user.dart';
import '../models/goal.dart';
import '../models/activity.dart';
import '../models/health_log.dart';
import '../models/step_record.dart';
import '../repositories/workout_record_repository.dart';
import '../models/workout_record.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lazy getters for repositories to break circular dependency
  GoalRepository get _goalRepo => GoalRepository();
  ActivityRepository get _activityRepo => ActivityRepository();
  HealthLogRepository get _healthLogRepo => HealthLogRepository();
  StepRecordRepository get _stepRecordRepo => StepRecordRepository();
  WorkoutRecordRepository get _workoutRecordRepo => WorkoutRecordRepository();

  /// Syncs all unsynced local data to Firestore
  Future<void> syncData(String userId) async {
    try {
      // 1. Sync Goals
      final unsyncedGoals = await _goalRepo.getUnsyncedGoals(userId);
      for (var goal in unsyncedGoals) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('goals')
            .doc(goal.id.toString())
            .set(goal.toMap());
        await _goalRepo.updateSyncStatus(goal.id!, 1);
      }

      // 2. Sync Activities
      final unsyncedActivities =
          await _activityRepo.getUnsyncedActivities(userId);
      for (var activity in unsyncedActivities) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('activities')
            .doc(activity.id.toString())
            .set(activity.toMap());
        await _activityRepo.updateSyncStatus(activity.id!, 1);
      }

      // 3. Sync Health Logs
      final unsyncedLogs = await _healthLogRepo.getUnsyncedLogs(userId);
      for (var log in unsyncedLogs) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('health_logs')
            .doc(log.id.toString())
            .set(log.toMap());
        await _healthLogRepo.updateSyncStatus(log.id!, 1);
      }

      // 4. Sync Step Records
      final unsyncedSteps = await _stepRecordRepo.getUnsyncedRecords(userId);
      for (var step in unsyncedSteps) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('step_records')
            .doc(step.id.toString())
            .set(step.toMap());
        await _stepRecordRepo.updateSyncStatus(step.id!, 1);
      }

      // 5. Sync Workout Records
      final unsyncedWorkouts = await _workoutRecordRepo.getUnsyncedWorkouts(userId);
      for (var workout in unsyncedWorkouts) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('workout_records')
            .doc(workout.id.toString())
            .set(workout.toMap());
        await _workoutRecordRepo.updateSyncStatus(workout.id!, 1);
      }

      debugPrint("Background sync completed for user: $userId");
    } catch (e) {
      debugPrint("Error during sync: $e");
    }
  }

  /// Pulls data from Firestore to local SQLite (Used after login)
  Future<void> rehydrateData(String userId) async {
    try {
      // 1. Rehydrate Goals
      final goalsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .get();
      for (var doc in goalsSnapshot.docs) {
        final data = doc.data();
        data['sync_status'] = 1; // Mark as synced locally
        final goal = Goal.fromMap(data);
        await _goalRepo.upsertGoal(goal);
      }

      // 2. Rehydrate Activities
      final activitiesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .get();
      for (var doc in activitiesSnapshot.docs) {
        final data = doc.data();
        data['sync_status'] = 1;
        final activity = Activity.fromMap(data);
        await _activityRepo.upsertActivity(activity);
      }

      // 3. Rehydrate Health Logs
      final logsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('health_logs')
          .get();
      for (var doc in logsSnapshot.docs) {
        final data = doc.data();
        data['sync_status'] = 1;
        final log = HealthLog.fromMap(data);
        await _healthLogRepo.upsertLog(log);
      }

      // 4. Rehydrate Step Records
      final stepsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('step_records')
          .get();
      for (var doc in stepsSnapshot.docs) {
        final data = doc.data();
        data['sync_status'] = 1;
        final step = StepRecord.fromMap(data);
        await _stepRecordRepo.upsertStepRecord(step);
      }

      // 5. Rehydrate Workout Records
      final workoutsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_records')
          .get();
      for (var doc in workoutsSnapshot.docs) {
        final data = doc.data();
        data['sync_status'] = 1;
        final workout = WorkoutRecord.fromMap(data);
        await _workoutRecordRepo.upsertWorkout(workout);
      }

      debugPrint("Rehydration completed for user: $userId");
    } catch (e) {
      debugPrint("Error during rehydration: $e");
    }
  }

  Future<void> syncGoal(dynamic goal) async {
    try {
      await _firestore
          .collection('users')
          .doc(goal.userId)
          .collection('goals')
          .doc(goal.id.toString())
          .set(goal.toMap());
      await _goalRepo.updateSyncStatus(goal.id!, 1);
    } catch (e) {
      debugPrint("Error syncing goal: $e");
    }
  }

  Future<void> deleteGoal(int goalId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId.toString())
          .delete();
      debugPrint("Goal deleted from Firestore: $goalId");
    } catch (e) {
      debugPrint("Error deleting goal from Firestore: $e");
    }
  }

  Future<void> syncActivity(dynamic activity) async {
    try {
      await _firestore
          .collection('users')
          .doc(activity.userId)
          .collection('activities')
          .doc(activity.id.toString())
          .set(activity.toMap());
      await _activityRepo.updateSyncStatus(activity.id!, 1);
    } catch (e) {
      debugPrint("Error syncing activity: $e");
    }
  }

  /// Pushes the User profile (including picture, age, weight, interests) to Firestore
  Future<void> syncUserProfile(User user) async {
    try {
      if (user.id == null) return;
      await _firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
      debugPrint("User profile synced successfully: ${user.id}");
    } catch (e) {
      debugPrint("Error syncing user profile: $e");
    }
  }
}
