import '../models/exercise_model.dart';
import 'api_service.dart';

class ExerciseService {
  const ExerciseService(this._apiService);

  final ApiService _apiService;

  Future<List<ExerciseModel>> fetchExercises({
    String? search,
    String? muscleGroup,
  }) async {
    final queryParameters = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (muscleGroup != null && muscleGroup != 'Alle') {
      queryParameters['muscleGroup'] = muscleGroup;
    }

    final query = Uri(queryParameters: queryParameters).query;
    final endpoint = query.isEmpty ? '/exercises' : '/exercises?$query';
    final response = await _apiService.get(endpoint) as List<dynamic>;

    return response
        .map((entry) => ExerciseModel.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> fetchMuscleGroups() async {
    final response =
        await _apiService.get('/exercises/meta/muscle-groups') as List<dynamic>;

    return response.map((entry) => entry.toString()).toList();
  }

  Future<void> createExercise({
    required String name,
    required String muscleGroup,
    required String description,
  }) async {
    await _apiService.post(
      '/exercises',
      authenticated: true,
      body: {
        'name': name,
        'muscle_group': muscleGroup,
        if (description.isNotEmpty) 'description': description,
      },
    );
  }
}
