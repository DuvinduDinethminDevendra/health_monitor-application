class HealthLog {
  final int? id; // SQLite auto-increment ID
  final String userId; // Firebase UID
  final double weight; // in kg or lbs
  final double height; // in cm or in
  final double bmi;
  final String date;
  final List<String> tags;
  final String? notes;
  final String unit; // 'metric' or 'imperial'
  final double? waist;
  final double? hip;
  final double? chest;
  final double? bodyFat;

  HealthLog({
    this.id,
    required this.userId,
    required this.weight,
    required this.height,
    double? bmi,
    String? date,
    this.tags = const [],
    this.notes,
    this.unit = 'metric',
    this.waist,
    this.hip,
    this.chest,
    this.bodyFat,
  })  : bmi = bmi ?? calculateBmi(weight, height, unit),
        date = date ?? DateTime.now().toIso8601String().split('T')[0];

  static double calculateBmi(double weight, double height, String unit) {
    if (height <= 0) return 0;
    if (unit == 'metric') {
      final heightInMeters = height / 100;
      return double.parse(
          (weight / (heightInMeters * heightInMeters)).toStringAsFixed(1));
    } else {
      // Imperial: (weight in lbs / (height in inches)^2 ) x 703
      return double.parse(((weight / (height * height)) * 703).toStringAsFixed(1));
    }
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'date': date,
      'tags': tags.join(','),
      'notes': notes,
      'unit': unit,
      'waist': waist,
      'hip': hip,
      'chest': chest,
      'body_fat': bodyFat,
    };
  }

  factory HealthLog.fromMap(Map<String, dynamic> map) {
    return HealthLog(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      weight: (map['weight'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      bmi: (map['bmi'] as num).toDouble(),
      date: map['date'] as String,
      tags: map['tags'] != null && map['tags'].toString().isNotEmpty
          ? map['tags'].toString().split(',')
          : [],
      notes: map['notes'] as String?,
      unit: map['unit'] as String? ?? 'metric',
      waist: map['waist'] != null ? (map['waist'] as num).toDouble() : null,
      hip: map['hip'] != null ? (map['hip'] as num).toDouble() : null,
      chest: map['chest'] != null ? (map['chest'] as num).toDouble() : null,
      bodyFat: map['body_fat'] != null ? (map['body_fat'] as num).toDouble() : null,
    );
  }
}

