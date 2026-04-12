import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthTipsService {
  static const String _baseUrl =
      'https://health.gov/myhealthfinder/api/v3/topicsearch.json';

  Future<List<HealthTip>> fetchHealthTips({String? keyword}) async {
    try {
      final uri = keyword != null && keyword.isNotEmpty
          ? Uri.parse('$_baseUrl?keyword=$keyword')
          : Uri.parse(_baseUrl);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final resources = data['Result']?['Resources']?['Resource'] as List?;

        if (resources == null) return _getFallbackTips();

        return resources.take(15).map((item) {
          return HealthTip(
            title: item['Title'] ?? 'Health Tip',
            description: _stripHtml(item['Categories'] ?? ''),
            content: _stripHtml(item['Sections']?['section']?[0]?['Content'] ?? ''),
            url: item['AccessibleVersion'] ?? '',
          );
        }).toList();
      }

      return _getFallbackTips();
    } catch (e) {
      return _getFallbackTips();
    }
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  List<HealthTip> _getFallbackTips() {
    return [
      HealthTip(
        title: 'Stay Hydrated',
        description: 'Nutrition',
        content: 'Drink at least 8 glasses of water daily to maintain proper hydration and support bodily functions.',
        url: '',
      ),
      HealthTip(
        title: 'Get Enough Sleep',
        description: 'Wellness',
        content: 'Aim for 7-9 hours of quality sleep each night. Good sleep improves mood, memory, and overall health.',
        url: '',
      ),
      HealthTip(
        title: 'Exercise Regularly',
        description: 'Fitness',
        content: 'Get at least 150 minutes of moderate aerobic activity or 75 minutes of vigorous activity per week.',
        url: '',
      ),
      HealthTip(
        title: 'Eat More Fruits & Vegetables',
        description: 'Nutrition',
        content: 'Fill half your plate with fruits and vegetables at each meal for essential vitamins and minerals.',
        url: '',
      ),
      HealthTip(
        title: 'Manage Stress',
        description: 'Mental Health',
        content: 'Practice relaxation techniques like deep breathing, meditation, or yoga to reduce stress levels.',
        url: '',
      ),
      HealthTip(
        title: 'Regular Health Checkups',
        description: 'Prevention',
        content: 'Schedule regular health screenings and checkups to detect potential issues early.',
        url: '',
      ),
      HealthTip(
        title: 'Limit Screen Time',
        description: 'Wellness',
        content: 'Take regular breaks from screens. Follow the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds.',
        url: '',
      ),
      HealthTip(
        title: 'Practice Good Posture',
        description: 'Fitness',
        content: 'Maintain proper posture while sitting and standing to prevent back pain and improve breathing.',
        url: '',
      ),
    ];
  }
}

class HealthTip {
  final String title;
  final String description;
  final String content;
  final String url;

  HealthTip({
    required this.title,
    required this.description,
    required this.content,
    required this.url,
  });
}
