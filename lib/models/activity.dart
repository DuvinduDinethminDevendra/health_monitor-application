class Activity {
  final int? id;
  final int userId;
  final String type; // 'steps' or 'workout'
  final double value;
  final String date;
  final int duration; // in minutes

  Activity({
    this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.date,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'value': value,
      'date': date,
      'duration': duration,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      value: (map['value'] as num).toDouble(),
      date: map['date'] as String,
      duration: map['duration'] as int,
    );
  }

  Activity copyWith({
    int? id,
    int? userId,
    String? type,
    double? value,
    String? date,
    int? duration,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      date: date ?? this.date,
      duration: duration ?? this.duration,
    );
  }
}
