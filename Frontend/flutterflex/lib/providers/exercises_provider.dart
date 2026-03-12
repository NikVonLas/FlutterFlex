import 'package:flutter/material.dart';

import '../models/exercise_model.dart';
import '../services/exercise_service.dart';

class ExercisesProvider extends ChangeNotifier {
  ExercisesProvider(this._exerciseService);

  final ExerciseService _exerciseService;

  List<ExerciseModel> _exercises = [];
  List<String> _muscleGroups = ['Alle'];
  String _selectedMuscleGroup = 'Alle';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<ExerciseModel> get exercises => _exercises.where((exercise) {
    final matchesGroup =
        _selectedMuscleGroup == 'Alle' ||
        exercise.muscleGroup == _selectedMuscleGroup;
    final matchesSearch =
        _searchQuery.isEmpty ||
        exercise.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        exercise.description.toLowerCase().contains(_searchQuery.toLowerCase());

    return matchesGroup && matchesSearch;
  }).toList();

  List<String> get muscleGroups => _muscleGroups;
  String get selectedMuscleGroup => _selectedMuscleGroup;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadExercises() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _exercises = await _exerciseService.fetchExercises();
      final groups = await _exerciseService.fetchMuscleGroups();
      _muscleGroups = ['Alle', ...groups];
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedMuscleGroup(String value) {
    _selectedMuscleGroup = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }
}
