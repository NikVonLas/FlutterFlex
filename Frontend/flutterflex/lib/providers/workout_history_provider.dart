import 'package:flutter/material.dart';

import '../models/workout_model.dart';
import '../services/workout_service.dart';

class WorkoutHistoryProvider extends ChangeNotifier {
  WorkoutHistoryProvider(this._workoutService);

  final WorkoutService _workoutService;

  List<WorkoutModel> _workouts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<WorkoutModel> get workouts => _workouts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadWorkouts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _workouts = await _workoutService.fetchHistory();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<MuscleGroupStat>> fetchMuscleGroupStats({int? days}) {
    return _workoutService.fetchMuscleGroupStats(days: days);
  }
}
