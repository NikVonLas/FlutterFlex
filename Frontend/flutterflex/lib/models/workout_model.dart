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
