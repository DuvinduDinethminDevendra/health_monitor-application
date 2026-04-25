import 'package:flutter/material.dart';
import '../services/health_tips_service.dart';

enum HealthTipsState { initial, loading, loaded, error, empty }

class HealthTipsProvider with ChangeNotifier {
  final HealthTipsService _service = HealthTipsService();
  
  HealthTipsState _state = HealthTipsState.initial;
  List<HealthTip> _tips = [];
  String _errorMessage = '';

  HealthTipsState get state => _state;
  List<HealthTip> get tips => _tips;
  String get errorMessage => _errorMessage;

  HealthTipsProvider() {
    fetchTips();
  }

  Future<void> fetchTips({String? keyword}) async {
    _state = HealthTipsState.loading;
    notifyListeners();

    try {
      final results = await _service.fetchHealthTips(keyword: keyword);
      if (results.isEmpty) {
        _state = HealthTipsState.empty;
        _tips = [];
      } else {
        _state = HealthTipsState.loaded;
        _tips = results;
      }
    } catch (e) {
      _state = HealthTipsState.error;
      _errorMessage = 'Failed to load health tips. Please check your connection and try again.';
      _tips = [];
    }
    notifyListeners();
  }

  void loadFallbackTips() {
    _state = HealthTipsState.loaded;
    _tips = _service.getFallbackTips();
    notifyListeners();
  }
}
