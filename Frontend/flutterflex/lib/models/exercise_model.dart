class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.description,
  });

  final int id;
  final String name;
  final String muscleGroup;
  final String description;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] as String,
      muscleGroup: json['muscle_group'] as String,
      description: (json['description'] ?? '') as String,
    );
  }
}
