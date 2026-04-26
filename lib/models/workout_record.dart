class WorkoutRecord {
  final int? id;
  final int userId;
  final String workoutType;
  final int durationMins;
  final int? caloriesBurned;
  final String loggedAt;
  final String? notes;

  WorkoutRecord({
    this.id,
    required this.userId,
    required this.workoutType,
    required this.durationMins,
    this.caloriesBurned,
    required this.loggedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'workout_type': workoutType,
      'duration_mins': durationMins,
      'calories_burned': caloriesBurned,
      'logged_at': loggedAt,
      'notes': notes,
    };
  }

  factory WorkoutRecord.fromMap(Map<String, dynamic> map) {
    return WorkoutRecord(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      workoutType: map['workout_type'] as String,
      durationMins: map['duration_mins'] as int,
      caloriesBurned: map['calories_burned'] as int?,
      loggedAt: map['logged_at'] as String,
      notes: map['notes'] as String?,
    );
  }

  WorkoutRecord copyWith({
    int? id,
    int? userId,
    String? workoutType,
    int? durationMins,
    int? caloriesBurned,
    String? loggedAt,
    String? notes,
  }) {
    return WorkoutRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutType: workoutType ?? this.workoutType,
      durationMins: durationMins ?? this.durationMins,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      loggedAt: loggedAt ?? this.loggedAt,
      notes: notes ?? this.notes,
    );
  }
}
