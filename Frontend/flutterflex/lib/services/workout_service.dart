import '../models/workout_model.dart';
import 'api_service.dart';

class WorkoutService {
  const WorkoutService(this._apiService);

  final ApiService _apiService;

  Future<List<WorkoutModel>> fetchHistory() async {
    final response =
        await _apiService.get('/workouts', authenticated: true)
            as List<dynamic>;

    return response
        .map((entry) => WorkoutModel.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutDetailModel> fetchWorkoutDetail(int workoutId) async {
    final response =
        await _apiService.get('/workouts/$workoutId', authenticated: true)
            as Map<String, dynamic>;

    return WorkoutDetailModel.fromJson(response);
  }

  Future<void> saveWorkout(Map<String, dynamic> payload) async {
    await _apiService.post('/workouts', authenticated: true, body: payload);
  }

  Future<void> updateWorkout(int workoutId, Map<String, dynamic> payload) async {
    await _apiService.put(
      '/workouts/$workoutId',
      authenticated: true,
      body: payload,
    );
  }

  Future<List<MuscleGroupStat>> fetchMuscleGroupStats({int? days}) async {
    final query = days != null ? '?days=$days' : '';
    final response = await _apiService.get(
      '/workouts/stats/muscle-groups$query',
      authenticated: true,
    ) as List<dynamic>;
    return response
        .map((e) => MuscleGroupStat.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
