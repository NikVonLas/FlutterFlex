import 'dart:async';

import 'package:flutter/material.dart';

import '../models/exercise_model.dart';
import '../services/workout_service.dart';

class TrackedWorkoutSet {
  TrackedWorkoutSet({this.weight = 0, this.reps = 8, this.isCompleted = false});

  double weight;
  int reps;
  bool isCompleted;
}

class TrackedExercise {
  TrackedExercise({required this.exercise, List<TrackedWorkoutSet>? sets})
    : sets = sets ?? [TrackedWorkoutSet()];

  final ExerciseModel exercise;
  final List<TrackedWorkoutSet> sets;
}

class WorkoutSessionProvider extends ChangeNotifier {
  WorkoutSessionProvider(this._workoutService);

  final WorkoutService _workoutService;

  final List<TrackedExercise> _exercises = [];
  Timer? _timer;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  String _workoutName = '';
  String _workoutType = 'Strength';
  bool _isSaving = false;
  String? _errorMessage;

  List<TrackedExercise> get exercises => _exercises;
  Duration get elapsed => _elapsed;
  bool get isSaving => _isSaving;
  bool get hasActiveSession => _startedAt != null;
  String get workoutName => _workoutName;
  String get workoutType => _workoutType;
  String? get errorMessage => _errorMessage;

  void startSessionIfNeeded() {
    if (_startedAt != null) {
      return;
    }

    _startedAt = DateTime.now();
    _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed = DateTime.now().difference(_startedAt!);
      notifyListeners();
    });
    notifyListeners();
  }

  void setWorkoutName(String value) {
    _workoutName = value;
    notifyListeners();
  }

  void setWorkoutType(String value) {
    _workoutType = value;
    notifyListeners();
  }

  void addExercise(ExerciseModel exercise) {
    startSessionIfNeeded();
    _exercises.add(TrackedExercise(exercise: exercise));
    notifyListeners();
  }

  void removeExercise(int exerciseIndex) {
    _exercises.removeAt(exerciseIndex);
    notifyListeners();
  }

  void addSet(int exerciseIndex) {
    _exercises[exerciseIndex].sets.add(TrackedWorkoutSet());
    notifyListeners();
  }

  void removeSet(int exerciseIndex, int setIndex) {
    final sets = _exercises[exerciseIndex].sets;
    if (sets.length == 1) {
      return;
    }

    sets.removeAt(setIndex);
    notifyListeners();
  }

  void updateSetWeight(int exerciseIndex, int setIndex, String value) {
    _exercises[exerciseIndex].sets[setIndex].weight =
        double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void updateSetReps(int exerciseIndex, int setIndex, String value) {
    _exercises[exerciseIndex].sets[setIndex].reps = int.tryParse(value) ?? 0;
  }

  void toggleSetCompleted(int exerciseIndex, int setIndex, bool value) {
    _exercises[exerciseIndex].sets[setIndex].isCompleted = value;
    notifyListeners();
  }

  Future<bool> finishWorkout() async {
    if (_startedAt == null || _exercises.isEmpty) {
      _errorMessage = 'Bitte fuege zuerst mindestens eine Uebung hinzu.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _workoutService.saveWorkout({
        'name': _workoutName.trim().isEmpty ? 'Premium Session' : _workoutName,
        'workoutType': _workoutType,
        'startTime': _startedAt!.toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'exercises': _exercises.map((exercise) {
          return {
            'exerciseId': exercise.exercise.id,
            'sets': exercise.sets.map((workoutSet) {
              return {
                'weight': workoutSet.weight,
                'reps': workoutSet.reps,
                'isCompleted': workoutSet.isCompleted,
                'durationSeconds': 0,
              };
            }).toList(),
          };
        }).toList(),
      });

      resetSession();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void resetSession() {
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
    _elapsed = Duration.zero;
    _exercises.clear();
    _workoutName = '';
    _workoutType = 'Strength';
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
