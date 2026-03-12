class WorkoutModel {
  const WorkoutModel({
    required this.id,
    required this.name,
    required this.workoutType,
    required this.startTime,
    required this.endTime,
    required this.totalVolume,
    required this.totalSets,
    required this.durationSeconds,
  });

  final int id;
  final String name;
  final String workoutType;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalVolume;
  final int totalSets;
  final int durationSeconds;

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: int.parse(json['id'].toString()),
      name: (json['name'] ?? 'Workout Session') as String,
      workoutType: (json['workout_type'] ?? 'Strength') as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'] as String)
          : null,
      totalVolume: double.tryParse(json['total_volume'].toString()) ?? 0,
      totalSets: int.tryParse((json['total_sets'] ?? 0).toString()) ?? 0,
      durationSeconds:
          int.tryParse((json['duration_seconds'] ?? 0).toString()) ?? 0,
    );
  }
}

class WorkoutSetModel {
  const WorkoutSetModel({
    required this.id,
    required this.exerciseId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.durationSeconds,
  });

  final int id;
  final int exerciseId;
  final int setNumber;
  final double weight;
  final int reps;
  final int durationSeconds;

  factory WorkoutSetModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSetModel(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      exerciseId: int.parse(json['exercise_id'].toString()),
      setNumber: int.tryParse((json['set_number'] ?? 1).toString()) ?? 1,
      weight: double.tryParse((json['weight'] ?? 0).toString()) ?? 0,
      reps: int.tryParse((json['reps'] ?? 0).toString()) ?? 0,
      durationSeconds:
          int.tryParse((json['duration_seconds'] ?? 0).toString()) ?? 0,
    );
  }
}

class WorkoutExerciseModel {
  const WorkoutExerciseModel({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  final int exerciseId;
  final String exerciseName;
  final List<WorkoutSetModel> sets;
}

class WorkoutDetailModel extends WorkoutModel {
  const WorkoutDetailModel({
    required super.id,
    required super.name,
    required super.workoutType,
    required super.startTime,
    required super.endTime,
    required super.totalVolume,
    required super.totalSets,
    required super.durationSeconds,
    required this.exercises,
  });

  final List<WorkoutExerciseModel> exercises;

  factory WorkoutDetailModel.fromJson(Map<String, dynamic> json) {
    final workout = WorkoutModel.fromJson(json);
    final groupedSets = <int, List<WorkoutSetModel>>{};
    final exerciseNames = <int, String>{};

    for (final entry in (json['sets'] as List<dynamic>? ?? const [])) {
      final setJson = entry as Map<String, dynamic>;
      final set = WorkoutSetModel.fromJson(setJson);
      groupedSets.putIfAbsent(set.exerciseId, () => <WorkoutSetModel>[]).add(set);
      exerciseNames.putIfAbsent(
        set.exerciseId,
        () => (setJson['exercise_name'] ?? 'Uebung') as String,
      );
    }

    final exercises = groupedSets.entries.map((entry) {
      entry.value.sort((left, right) => left.setNumber.compareTo(right.setNumber));
      return WorkoutExerciseModel(
        exerciseId: entry.key,
        exerciseName: exerciseNames[entry.key] ?? 'Uebung',
        sets: entry.value,
      );
    }).toList();

    return WorkoutDetailModel(
      id: workout.id,
      name: workout.name,
      workoutType: workout.workoutType,
      startTime: workout.startTime,
      endTime: workout.endTime,
      totalVolume: workout.totalVolume,
      totalSets: workout.totalSets,
      durationSeconds: workout.durationSeconds,
      exercises: exercises,
    );
  }
}

class MuscleGroupStat {
  const MuscleGroupStat({
    required this.muscleGroup,
    required this.workoutCount,
    required this.setCount,
  });

  final String muscleGroup;
  final int workoutCount;
  final int setCount;

  factory MuscleGroupStat.fromJson(Map<String, dynamic> json) {
    return MuscleGroupStat(
      muscleGroup: json['muscle_group'] as String,
      workoutCount: int.parse(json['workout_count'].toString()),
      setCount: int.parse(json['set_count'].toString()),
    );
  }
}
