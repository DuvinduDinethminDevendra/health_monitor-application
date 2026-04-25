import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';
import '../models/activity.dart';
import '../models/health_log.dart';
import '../repositories/goal_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/health_log_repository.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final GoalRepository _goalRepo = GoalRepository();
  final ActivityRepository _activityRepo = ActivityRepository();
  final HealthLogRepository _healthLogRepo = HealthLogRepository();

  // --- GOAL SYNC ---
  Future<void> syncGoal(Goal goal) async {
    try {
      await _firestore
          .collection('users')
          .doc(goal.userId)
          .collection('goals')
          .doc(goal.id.toString())
          .set(goal.toMap());
    } catch (e) {
      print('Error syncing goal: $e');
    }
  }

  // --- ACTIVITY SYNC ---
  Future<void> syncActivity(Activity activity) async {
    try {
      await _firestore
          .collection('users')
          .doc(activity.userId)
          .collection('activities')
          .doc(activity.id.toString())
          .set(activity.toMap());
    } catch (e) {
      print('Error syncing activity: $e');
    }
  }

  // --- HEALTH LOG SYNC ---
  Future<void> syncHealthLog(HealthLog log) async {
    try {
      await _firestore
          .collection('users')
          .doc(log.userId)
          .collection('health_logs')
          .doc(log.id.toString())
          .set(log.toMap());
    } catch (e) {
      print('Error syncing health log: $e');
    }
  }

  // --- DATA REHYDRATION (Cloud to Local) ---
  Future<void> rehydrateData(String userId) async {
    try {
      // 1. Rehydrate Goals
      final goalSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .get();
      
      for (var doc in goalSnapshot.docs) {
        final goal = Goal.fromMap(doc.data());
        await _goalRepo.insertGoal(goal);
      }

      // 2. Rehydrate Activities
      final activitySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .get();
      
      for (var doc in activitySnapshot.docs) {
        final activity = Activity.fromMap(doc.data());
        await _activityRepo.insertActivity(activity);
      }

      // 3. Rehydrate Health Logs
      final healthLogSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('health_logs')
          .get();
      
      for (var doc in healthLogSnapshot.docs) {
        final log = HealthLog.fromMap(doc.data());
        await _healthLogRepo.insertHealthLog(log);
      }
    } catch (e) {
      print('Error rehydrating data: $e');
    }
  }
}
