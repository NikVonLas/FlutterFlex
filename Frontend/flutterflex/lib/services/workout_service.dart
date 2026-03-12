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

  Future<void> saveWorkout(Map<String, dynamic> payload) async {
    await _apiService.post('/workouts', authenticated: true, body: payload);
  }
}
