import 'package:flutter/foundation.dart';
import '../models/health_log.dart';
import '../services/health_log_service.dart';

class HealthLogProvider with ChangeNotifier {
  final HealthLogService _service = HealthLogService();
  
  List<HealthLog> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _streakCount = 0;

  // Getters
  List<HealthLog> get logs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get streakCount => _streakCount;

  /// Loads all logs for a specific user and calculates the current streak using the service.
  Future<void> loadLogs(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await _service.getLogs(userId);
      _streakCount = _service.calculateCurrentStreak(_logs);
      _isLoading = false;
    } catch (e) {
      _errorMessage = "Failed to load health logs: $e";
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Adds a new health log entry via the service.
  Future<bool> addLog(HealthLog log) async {
    try {
      await _service.saveLog(log);
      await loadLogs(log.userId);
      return true;
    } catch (e) {
      _errorMessage = "Failed to add log: $e";
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing health log entry via the service.
  Future<bool> updateLog(HealthLog log) async {
    try {
      if (log.id == null) return false;
      await _service.updateLog(log);
      await loadLogs(log.userId);
      return true;
    } catch (e) {
      _errorMessage = "Failed to update log: $e";
      notifyListeners();
      return false;
    }
  }

  /// Deletes a health log entry via the service.
  Future<bool> deleteLog(int id, String userId) async {
    try {
      await _service.deleteLog(id);
      await loadLogs(userId);
      return true;
    } catch (e) {
      _errorMessage = "Failed to delete log: $e";
      notifyListeners();
      return false;
    }
  }
}
