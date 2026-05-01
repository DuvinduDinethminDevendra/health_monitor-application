import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class HealthTipsService {
  static const String _baseUrl =
      'https://health.gov/myhealthfinder/api/v3/topicsearch.json';

  Dio? _dio;

  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    
    CacheStore cacheStore;
    
    if (kIsWeb) {
      cacheStore = MemCacheStore();
    } else {
      final dir = await getApplicationDocumentsDirectory();
      cacheStore = HiveCacheStore(
        dir.path,
        hiveBoxName: "health_tips_cache",
      );
    }
    
    final cacheOptions = CacheOptions(
      store: cacheStore,
      policy: CachePolicy.forceCache, // Hit disk immediately for instant feel
      hitCacheOnErrorExcept: [401, 403],
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      cipher: null,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false,
    );
    
    _dio = Dio()
      ..interceptors.add(DioCacheInterceptor(options: cacheOptions));
      
    return _dio!;
  }

  Future<List<HealthTip>> fetchHealthTips({String? keyword, bool forceRefresh = false}) async {
    try {
      final isSearch = keyword != null && keyword.isNotEmpty;
      final url = isSearch ? '$_baseUrl?keyword=$keyword' : _baseUrl;

      final client = await _client;
      
      final options = forceRefresh 
          ? Options(extra: { 'cache_policy': CachePolicy.refreshForceCache }) 
          : null;

      final response = await client.get(url, options: options);

      if (response.statusCode == 200 || response.statusCode == 304) {
        final data = response.data;
        final resources = data['Result']?['Resources']?['Resource'] as List?;

        if (resources == null) {
          return getFallbackTips();
        }

        final List<dynamic> modifiableResources = List.from(resources);

        if (!isSearch) {
          modifiableResources.shuffle();
        }

        final tipsToReturn = isSearch ? modifiableResources : modifiableResources.take(20);

        return tipsToReturn.map((item) {
          String? imageUrl = item['ImageUrl'];
          if (imageUrl == null && item['Image'] != null) {
            imageUrl = item['Image']?['Url'];
          }

          return HealthTip(
            id: item['Id']?.toString() ?? '',
            title: item['Title'] ?? 'Health Tip',
            description: _stripHtml(item['Categories'] ?? ''),
            content: item['Sections']?['section']?[0]?['Content'] ?? '',
            url: item['AccessibleVersion'] ?? '',
            imageUrl: imageUrl,
          );
        }).toList();
      } else {
        return getFallbackTips();
      }
    } catch (e) {
      // On Web, CORS often blocks this request. Return fallback data to keep UI populated.
      return getFallbackTips();
    }
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  List<HealthTip> getFallbackTips() {
    return [
      HealthTip(
        id: 'fallback_1',
        title: 'Stay Hydrated',
        description: 'Nutrition',
        content: 'Drink at least 8 glasses of water daily to maintain proper hydration and support bodily functions.',
        url: '',
      ),
      HealthTip(
        id: 'fallback_2',
        title: 'Get Enough Sleep',
        description: 'Wellness',
        content: 'Aim for 7-9 hours of quality sleep each night. Good sleep improves mood, memory, and overall health.',
        url: '',
      ),
      HealthTip(
        id: 'fallback_3',
        title: 'Exercise Regularly',
        description: 'Fitness',
        content: 'Get at least 150 minutes of moderate aerobic activity or 75 minutes of vigorous activity per week.',
        url: '',
      ),
      HealthTip(
        id: 'fallback_4',
        title: 'Eat More Fruits & Vegetables',
        description: 'Nutrition',
        content: 'Fill half your plate with fruits and vegetables at each meal for essential vitamins and minerals.',
        url: '',
      ),
      HealthTip(
        id: 'fallback_5',
        title: 'Manage Stress',
        description: 'Mental Health',
        content: 'Practice relaxation techniques like deep breathing, meditation, or yoga to reduce stress levels.',
        url: '',
      ),
      HealthTip(
        id: 'fallback_6',
        title: 'Regular Health Checkups',
        description: 'Prevention',
        content: 'Schedule regular health screenings and checkups to detect potential issues early.',
        url: '',
      ),
      HealthTip(
        id: 'fallback_7',
        title: 'Limit Screen Time',
        description: 'Wellness',
        content: 'Take regular breaks from screens. Follow the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds.',
        url: '',
      ),
      HealthTip(
        id: 'fallback_8',
        title: 'Practice Good Posture',
        description: 'Fitness',
        content: 'Maintain proper posture while sitting and standing to prevent back pain and improve breathing.',
        url: '',
        imageUrl: null,
      ),
    ];
  }

  Future<void> saveFavoriteTip(HealthTip tip) async {
    final db = await DatabaseHelper().database;
    await db.insert('favorite_tips', {
      'topic_id': tip.id,
      'title': tip.title,
      'description': tip.description,
      'content': tip.content,
      'url': tip.url,
      'image_url': tip.imageUrl,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFavoriteTip(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete('favorite_tips', where: 'topic_id = ?', whereArgs: [id]);
  }

  Future<List<HealthTip>> getFavoriteTips() async {
    final db = await DatabaseHelper().database;
    final maps = await db.query('favorite_tips');
    return maps.map((map) => HealthTip(
      id: map['topic_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      content: map['content'] as String,
      url: map['url'] as String,
      imageUrl: map['image_url'] as String?,
    )).toList();
  }

  Future<void> saveRecentTip(HealthTip tip) async {
    final db = await DatabaseHelper().database;
    await db.insert('recent_tips', {
      'topic_id': tip.id,
      'title': tip.title,
      'description': tip.description,
      'content': tip.content,
      'url': tip.url,
      'visited_at': DateTime.now().millisecondsSinceEpoch,
      'image_url': tip.imageUrl,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    
    await db.execute('''
      DELETE FROM recent_tips 
      WHERE topic_id NOT IN (
        SELECT topic_id FROM recent_tips ORDER BY visited_at DESC LIMIT 20
      )
    ''');
  }

  Future<List<HealthTip>> getRecentTips() async {
    final db = await DatabaseHelper().database;
    final maps = await db.query('recent_tips', orderBy: 'visited_at DESC');
    return maps.map((map) => HealthTip(
      id: map['topic_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      content: map['content'] as String,
      url: map['url'] as String,
      imageUrl: map['image_url'] as String?,
    )).toList();
  }
}

class HealthTip {
  final String id;
  final String title;
  final String description;
  final String content;
  final String url;
  final String? imageUrl;

  HealthTip({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.url,
    String? imageUrl,
  }) : imageUrl = _processImageUrl(imageUrl);

  static String? _processImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('/')) {
      return 'https://health.gov$url';
    }
    if (!url.startsWith('http')) {
      return 'https://$url';
    }
    return url;
  }
}
