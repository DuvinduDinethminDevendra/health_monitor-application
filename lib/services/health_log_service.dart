import 'package:intl/intl.dart';
import '../models/health_log.dart';
import '../repositories/health_log_repository.dart';

class HealthLogService {
  final HealthLogRepository _repository = HealthLogRepository();

  /// Fetches logs for a user from the repository.
  Future<List<HealthLog>> getLogs(String userId) async {
    return await _repository.getHealthLogsByUser(userId);
  }

  /// Saves a new log entry.
  Future<void> saveLog(HealthLog log) async {
    await _repository.insertHealthLog(log);
  }

  /// Updates an existing log entry.
  Future<void> updateLog(HealthLog log) async {
    await _repository.updateHealthLog(log);
  }

  /// Deletes a log entry.
  Future<void> deleteLog(int id) async {
    await _repository.deleteHealthLog(id);
  }

  /// Calculates the current logging streak based on a list of logs.
  /// Logic moved here to keep the Provider focused on state.
  int calculateCurrentStreak(List<HealthLog> logs) {
    if (logs.isEmpty) return 0;

    // Ensure logs are sorted by date descending
    final sortedLogs = List<HealthLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    final uniqueDates = sortedLogs.map((l) => l.date).toSet().toList();
    if (uniqueDates.isEmpty) return 0;

    DateTime today = DateTime.now();
    String todayStr = DateFormat('yyyy-MM-dd').format(today);
    String yesterdayStr = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)));

    int streak = 0;

    // Start streak if latest entry is today or yesterday
    if (uniqueDates.first == todayStr || uniqueDates.first == yesterdayStr) {
      DateTime currentDate = DateTime.parse(uniqueDates.first);
      streak++;

      for (int i = 1; i < uniqueDates.length; i++) {
        DateTime prevDate = DateTime.parse(uniqueDates[i]);
        if (currentDate.difference(prevDate).inDays == 1) {
          streak++;
          currentDate = prevDate;
        } else {
          break;
        }
      }
    }
    return streak;
  }

  /// Future expansion: Logic for syncing with cloud, generating PDF reports, etc.
}
