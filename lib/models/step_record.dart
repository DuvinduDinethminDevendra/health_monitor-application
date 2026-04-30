class StepRecord {
  final int? id;
  final String userId;
  final String date;
  final int stepCount;
  final int goal;

  StepRecord({
    this.id,
    required this.userId,
    required this.date,
    required this.stepCount,
    this.goal = 10000,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': date,
      'step_count': stepCount,
      'goal': goal,
    };
  }

  factory StepRecord.fromMap(Map<String, dynamic> map) {
    return StepRecord(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      date: map['date'] as String,
      stepCount: map['step_count'] as int,
      goal: map['goal'] as int? ?? 10000,
    );
  }

  StepRecord copyWith({
    int? id,
    String? userId,
    String? date,
    int? stepCount,
    int? goal,
  }) {
    return StepRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      stepCount: stepCount ?? this.stepCount,
      goal: goal ?? this.goal,
    );
  }
}
