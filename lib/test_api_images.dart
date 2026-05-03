import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final response = await dio.get('https://health.gov/myhealthfinder/api/v3/topicsearch.json');
  final data = response.data;
  final resources = data['Result']?['Resources']?['Resource'] as List?;

  if (resources != null) {
    debugPrint("Total resources: ${resources.length}\n");
    
    int hasImage = 0;
    int noImage = 0;
    
    for (int i = 0; i < resources.length && i < 15; i++) {
      final item = resources[i];
      final title = item['Title'] ?? 'N/A';
      final imageUrl = item['ImageUrl'] ?? 'NO IMAGE FIELD';
      final imageAlt = item['ImageAlt'] ?? 'NO ALT';
      
      debugPrint("[$i] Title: $title");
      debugPrint("    ImageUrl: $imageUrl");
      debugPrint("    ImageAlt: $imageAlt");
      debugPrint("");
      
      if (imageUrl != null && imageUrl.toString().isNotEmpty && imageUrl != 'NO IMAGE FIELD') {
        hasImage++;
      } else {
        noImage++;
      }
    }
    
    debugPrint("---");
    debugPrint("With image: $hasImage / 15 sampled");
    debugPrint("Without image: $noImage / 15 sampled");
  }
}
