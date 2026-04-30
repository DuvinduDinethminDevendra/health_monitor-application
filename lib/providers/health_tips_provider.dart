import 'package:flutter/material.dart';
import '../services/health_tips_service.dart';

enum HealthTipsState { initial, loading, loaded, error, empty }

class HealthTipsProvider with ChangeNotifier {
  final HealthTipsService _service = HealthTipsService();
  
  HealthTipsState _state = HealthTipsState.initial;
  List<HealthTip> _tips = [];
  String _errorMessage = '';

  String? _selectedTag = 'Trending';
  String _currentSearchQuery = '';
  Set<String> _favoriteTipIds = {};

  HealthTipsState get state => _state;
  List<HealthTip> get tips => _tips;
  String get errorMessage => _errorMessage;
  String? get selectedTag => _selectedTag;

  HealthTipsProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    await _loadFavoriteIds();
    fetchTipsByTag('Trending');
  }

  Future<void> _loadFavoriteIds() async {
    final favs = await _service.getFavoriteTips();
    _favoriteTipIds = favs.map((e) => e.id).toSet();
    notifyListeners();
  }

  bool isFavorite(String id) => _favoriteTipIds.contains(id);

  Future<void> toggleFavorite(HealthTip tip) async {
    if (isFavorite(tip.id)) {
      await _service.removeFavoriteTip(tip.id);
      _favoriteTipIds.remove(tip.id);
      
      if (_selectedTag == 'Favorites') {
        _tips.removeWhere((t) => t.id == tip.id);
        if (_tips.isEmpty) _state = HealthTipsState.empty;
      }
    } else {
      await _service.saveFavoriteTip(tip);
      _favoriteTipIds.add(tip.id);
    }
    notifyListeners();
  }
  
  Future<void> markAsRecent(HealthTip tip) async {
    await _service.saveRecentTip(tip);
  }

  Future<void> fetchTipsByTag(String tag, {bool forceRefresh = false}) async {
    _selectedTag = tag;
    _state = HealthTipsState.loading;
    notifyListeners();

    try {
      List<HealthTip> results = [];
      if (tag == 'Favorites') {
        results = await _service.getFavoriteTips();
      } else if (tag == 'Recent') {
        results = await _service.getRecentTips();
      } else if (tag == 'Trending') {
        results = await _service.fetchHealthTips(keyword: '', forceRefresh: forceRefresh);
      } else {
        results = await _service.fetchHealthTips(keyword: tag, forceRefresh: forceRefresh);
      }

      if (results.isEmpty) {
        _state = HealthTipsState.empty;
        _tips = [];
      } else {
        _state = HealthTipsState.loaded;
        _tips = results;
      }
    } catch (e, stacktrace) {
      print("HealthTipsProvider Error: $e\\n$stacktrace");
      _state = HealthTipsState.error;
      _errorMessage = 'Failed to load health tips. Please check your connection and try again.';
      _tips = [];
    }
    notifyListeners();
  }

  Future<void> searchTips(String keyword, {bool forceRefresh = false}) async {
    _currentSearchQuery = keyword.trim();
    final searchKeyword = _currentSearchQuery;
    if (searchKeyword.isEmpty) {
      return fetchTipsByTag('Trending');
    }
    
    _selectedTag = null;
    _state = HealthTipsState.loading;
    notifyListeners();

    try {
      final results = await _service.fetchHealthTips(keyword: searchKeyword, forceRefresh: forceRefresh);
      if (results.isEmpty) {
        _state = HealthTipsState.empty;
        _tips = [];
      } else {
        _state = HealthTipsState.loaded;
        _tips = results;
      }
    } catch (e, stacktrace) {
      print("HealthTipsProvider Error: $e\\n$stacktrace");
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

  Future<void> refreshCurrentList() async {
    if (_selectedTag != null) {
      return fetchTipsByTag(_selectedTag!, forceRefresh: true);
    } else {
      return searchTips(_currentSearchQuery, forceRefresh: true);
    }
  }
}
