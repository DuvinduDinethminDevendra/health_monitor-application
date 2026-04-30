import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final response = await dio.get('https://health.gov/myhealthfinder/api/v3/topicsearch.json');
  final data = response.data;
  final resources = data['Result']?['Resources']?['Resource'] as List?;

  if (resources != null) {
    print("Total resources: ${resources.length}\n");
    
    int hasImage = 0;
    int noImage = 0;
    
    for (int i = 0; i < resources.length && i < 15; i++) {
      final item = resources[i];
      final title = item['Title'] ?? 'N/A';
      final imageUrl = item['ImageUrl'] ?? 'NO IMAGE FIELD';
      final imageAlt = item['ImageAlt'] ?? 'NO ALT';
      
      print("[$i] Title: $title");
      print("    ImageUrl: $imageUrl");
      print("    ImageAlt: $imageAlt");
      print("");
      
      if (imageUrl != null && imageUrl.toString().isNotEmpty && imageUrl != 'NO IMAGE FIELD') {
        hasImage++;
      } else {
        noImage++;
      }
    }
    
    print("---");
    print("With image: $hasImage / 15 sampled");
    print("Without image: $noImage / 15 sampled");
  }
}
