class HealthLog {
  final int? id;
  final int userId;
  final double weight; // in kg
  final double height; // in cm
  final double bmi;
  final String date;

  HealthLog({
    this.id,
    required this.userId,
    required this.weight,
    required this.height,
    double? bmi,
    String? date,
  })  : bmi = bmi ?? _calculateBmi(weight, height),
        date = date ?? DateTime.now().toIso8601String().split('T')[0];

  static double _calculateBmi(double weight, double height) {
    if (height <= 0) return 0;
    final heightInMeters = height / 100;
    return double.parse(
        (weight / (heightInMeters * heightInMeters)).toStringAsFixed(1));
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
    };
  }

  factory HealthLog.fromMap(Map<String, dynamic> map) {
    return HealthLog(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      weight: (map['weight'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      bmi: (map['bmi'] as num).toDouble(),
      date: map['date'] as String,
    );
  }
}
