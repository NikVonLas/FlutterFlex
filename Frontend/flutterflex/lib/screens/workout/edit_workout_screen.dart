import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/exercises_provider.dart';
import '../../services/workout_service.dart';

class EditWorkoutScreen extends StatefulWidget {
  const EditWorkoutScreen({required this.workoutId, super.key});

  final int workoutId;

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  final _nameController = TextEditingController();
  final _customTypeController = TextEditingController();
  final List<String> _workoutTypes = ['Strength', 'Push', 'Pull', 'Legs'];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _workoutType = 'Strength';
  DateTime? _startTime;
  Duration _duration = const Duration(minutes: 45);
  List<_EditableExercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkout();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<ExercisesProvider>().loadExercises();
      if (!mounted) {
        return;
      }

      final workout = await context.read<WorkoutService>().fetchWorkoutDetail(
        widget.workoutId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _nameController.text = workout.name;
        _workoutType = workout.workoutType;
        if (workout.workoutType.trim().isNotEmpty &&
            !_workoutTypes.contains(workout.workoutType)) {
          _workoutTypes.add(workout.workoutType);
          _customTypeController.text = workout.workoutType;
        }
        _startTime = workout.startTime;
        _duration = Duration(
          seconds: workout.durationSeconds > 0
              ? workout.durationSeconds
              : (workout.endTime?.difference(workout.startTime).inSeconds ??
                    2700),
        );
        _exercises = workout.exercises
            .map(
              (exercise) => _EditableExercise(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                sets: exercise.sets
                    .map(
                      (set) => _EditableSet(
                        weight: set.weight,
                        reps: set.reps,
                        durationSeconds: set.durationSeconds,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    if (_startTime == null) {
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startTime!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _startTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _startTime!.hour,
        _startTime!.minute,
        _startTime!.second,
      );
    });
  }

  Future<void> _openExercisePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Consumer<ExercisesProvider>(
            builder: (context, provider, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: provider.exercises.map((exercise) {
                  return ListTile(
                    title: Text(exercise.name),
                    subtitle: Text(exercise.muscleGroup),
                    onTap: () {
                      setState(() {
                        final existingIndex = _exercises.indexWhere(
                          (entry) => entry.exerciseId == exercise.id,
                        );

                        if (existingIndex >= 0) {
                          _exercises[existingIndex].sets.add(_EditableSet());
                        } else {
                          _exercises.add(
                            _EditableExercise(
                              exerciseId: exercise.id,
                              exerciseName: exercise.name,
                              sets: [_EditableSet()],
                            ),
                          );
                        }
                      });
                      Navigator.of(sheetContext).pop();
                    },
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  void _applyCustomWorkoutType() {
    final customType = _customTypeController.text.trim();
    if (customType.isEmpty) {
      return;
    }

    if (!_workoutTypes.contains(customType)) {
      _workoutTypes.add(customType);
    }

    setState(() {
      _workoutType = customType;
    });
  }

  Future<void> _saveWorkout() async {
    if (_startTime == null || _exercises.isEmpty) {
      setState(() {
        _errorMessage = 'Bitte mindestens eine Uebung im Workout behalten.';
      });
      return;
    }

    _applyCustomWorkoutType();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await context.read<WorkoutService>().updateWorkout(widget.workoutId, {
        'name': _nameController.text.trim().isEmpty
            ? 'Workout Session'
            : _nameController.text.trim(),
        'workoutType': _workoutType,
        'startTime': _startTime!.toIso8601String(),
        'endTime': _startTime!.add(_duration).toIso8601String(),
        'exercises': _exercises.map((exercise) {
          return {
            'exerciseId': exercise.exerciseId,
            'sets': exercise.sets.map((set) {
              return {
                'weight': set.weight,
                'reps': set.reps,
                'durationSeconds': set.durationSeconds,
              };
            }).toList(),
          };
        }).toList(),
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout bearbeiten')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ElevatedButton.icon(
            onPressed: _isLoading || _isSaving ? null : _saveWorkout,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Aenderungen speichern'),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _exercises.isEmpty
          ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_errorMessage!),
            ))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Workout-Name',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          children: _workoutTypes.map((type) {
                            return ChoiceChip(
                              label: Text(type),
                              selected: type == _workoutType,
                              onSelected: (_) {
                                setState(() {
                                  _workoutType = type;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customTypeController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Eigener Workout-Typ',
                            prefixIcon: const Icon(Icons.add_box_outlined),
                            suffixIcon: IconButton(
                              tooltip: 'Typ uebernehmen',
                              onPressed: _applyCustomWorkoutType,
                              icon: const Icon(Icons.check_rounded),
                            ),
                          ),
                          onSubmitted: (_) => _applyCustomWorkoutType(),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            _startTime == null
                                ? 'Datum waehlen'
                                : 'Datum: ${MaterialLocalizations.of(context).formatMediumDate(_startTime!)}',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dauer: ${_duration.inMinutes} Minuten',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _openExercisePicker,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Uebung hinzufuegen'),
                ),
                const SizedBox(height: 18),
                ..._exercises.asMap().entries.map((entry) {
                  final exerciseIndex = entry.key;
                  final exercise = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    exercise.exerciseName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _exercises.removeAt(exerciseIndex);
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...exercise.sets.asMap().entries.map((setEntry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _EditableSetEditor(
                                  key: ValueKey('${exercise.exerciseId}-${setEntry.key}'),
                                  setNumber: setEntry.key + 1,
                                  workoutSet: setEntry.value,
                                  onWeightChanged: (value) {
                                    exercise.sets[setEntry.key].weight =
                                        double.tryParse(
                                              value.replaceAll(',', '.'),
                                            ) ??
                                        0;
                                  },
                                  onRepsChanged: (value) {
                                    exercise.sets[setEntry.key].reps =
                                        int.tryParse(value) ?? 0;
                                  },
                                  onDelete: () {
                                    setState(() {
                                      if (exercise.sets.length == 1) {
                                        return;
                                      }
                                      exercise.sets.removeAt(setEntry.key);
                                    });
                                  },
                                ),
                              );
                            }),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  exercise.sets.add(_EditableSet());
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              label: const Text('Satz hinzufuegen'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _EditableExercise {
  _EditableExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  final int exerciseId;
  final String exerciseName;
  final List<_EditableSet> sets;
}

class _EditableSet {
  _EditableSet({this.weight = 0, this.reps = 8, this.durationSeconds = 0});

  double weight;
  int reps;
  int durationSeconds;
}

class _EditableSetEditor extends StatefulWidget {
  const _EditableSetEditor({
    super.key,
    required this.setNumber,
    required this.workoutSet,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onDelete,
  });

  final int setNumber;
  final _EditableSet workoutSet;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onRepsChanged;
  final VoidCallback onDelete;

  @override
  State<_EditableSetEditor> createState() => _EditableSetEditorState();
}

class _EditableSetEditorState extends State<_EditableSetEditor> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.workoutSet.weight.toStringAsFixed(0),
    );
    _repsController = TextEditingController(
      text: widget.workoutSet.reps.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _EditableSetEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workoutSet.weight != widget.workoutSet.weight) {
      _weightController.text = widget.workoutSet.weight.toStringAsFixed(0);
    }
    if (oldWidget.workoutSet.reps != widget.workoutSet.reps) {
      _repsController.text = widget.workoutSet.reps.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(width: 34, child: Text('#${widget.setNumber}')),
          Expanded(
            child: TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'kg'),
              onChanged: widget.onWeightChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
              onChanged: widget.onRepsChanged,
            ),
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}