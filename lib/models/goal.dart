class Goal {
  final int? id;
  final int userId;
  final String title;
  final double targetValue;
  final double currentValue;
  final String unit;
  final String deadline;
  final bool isCompleted;

  Goal({
    this.id,
    required this.userId,
    required this.title,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    required this.deadline,
    this.isCompleted = false,
  });

  double get progressPercent {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue * 100).clamp(0, 100);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'deadline': deadline,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      targetValue: (map['target_value'] as num).toDouble(),
      currentValue: (map['current_value'] as num).toDouble(),
      unit: map['unit'] as String,
      deadline: map['deadline'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }

  Goal copyWith({
    int? id,
    int? userId,
    String? title,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? deadline,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
