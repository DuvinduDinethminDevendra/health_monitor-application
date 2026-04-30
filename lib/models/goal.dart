class Goal {
  final int? id; // SQLite auto-increment ID
  final String userId; // Firebase UID
  final String title;
  final String category; // e.g., 'Running', 'Diet', 'Water', 'General'
  final double targetValue;
  final double currentValue;
  final String unit;
  final String deadline;
  final String? reminderTime; // e.g., '08:00 AM'
  final bool isCompleted;

  Goal({
    this.id,
    required this.userId,
    required this.title,
    this.category = 'General',
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    required this.deadline,
    this.reminderTime,
    this.isCompleted = false,
  });

  double get progressPercent {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue * 100).clamp(0, 100);
  }

  String get baseType {
    final cat = category.replaceAll(' (Daily)', '').replaceAll(' (Cumulative)', '').toLowerCase();
    if (cat == 'general' || cat == 'custom') {
      return title.toLowerCase();
    }
    return cat;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'category': category,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'deadline': deadline,
      'reminder_time': reminderTime,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'General',
      targetValue: (map['target_value'] as num).toDouble(),
      currentValue: (map['current_value'] as num).toDouble(),
      unit: map['unit'] as String,
      deadline: map['deadline'] as String,
      reminderTime: map['reminder_time'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }

  Goal copyWith({
    int? id,
    String? userId,
    String? title,
    String? category,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? deadline,
    String? reminderTime,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      deadline: deadline ?? this.deadline,
      reminderTime: reminderTime ?? this.reminderTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
