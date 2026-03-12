import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/exercises_provider.dart';
import '../../providers/workout_history_provider.dart';
import '../../providers/workout_session_provider.dart';

class WorkoutTrackerScreen extends StatefulWidget {
  const WorkoutTrackerScreen({
    this.initialManualEntry = false,
    this.initialManualStartAt,
    this.initialManualDuration,
    super.key,
  });

  final bool initialManualEntry;
  final DateTime? initialManualStartAt;
  final Duration? initialManualDuration;

  @override
  State<WorkoutTrackerScreen> createState() => _WorkoutTrackerScreenState();
}

class _WorkoutTrackerScreenState extends State<WorkoutTrackerScreen> {
  final _nameController = TextEditingController();
  final _customTypeController = TextEditingController();
  final List<String> _workoutTypes = ['Strength', 'Push', 'Pull', 'Legs'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutSessionProvider>().initializeSession(
        manualEntry: widget.initialManualEntry,
        manualStartAt: widget.initialManualStartAt,
        manualDuration: widget.initialManualDuration,
      );
      context.read<ExercisesProvider>().loadExercises();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  void _applyCustomWorkoutType() {
    final customType = _customTypeController.text.trim();
    if (customType.isEmpty) return;
    final workoutSession = context.read<WorkoutSessionProvider>();
    setState(() {
      if (!_workoutTypes.contains(customType)) {
        _workoutTypes.add(customType);
      }
    });
    workoutSession.setWorkoutType(customType);
  }

  Future<void> _openExercisePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Consumer<ExercisesProvider>(
            builder: (context, provider, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: provider.exercises.map((exercise) {
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: Text(exercise.name),
                    subtitle: Text(exercise.muscleGroup),
                    onTap: () {
                      context.read<WorkoutSessionProvider>().addExercise(
                        exercise,
                      );
                      Navigator.of(context).pop();
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

  Future<void> _finishWorkout() async {
    final workoutSession = context.read<WorkoutSessionProvider>();
    workoutSession.setWorkoutName(_nameController.text.trim());

    final success = await workoutSession.finishWorkout();
    if (!mounted) {
      return;
    }

    if (success) {
      await context.read<WorkoutHistoryProvider>().loadWorkouts();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          workoutSession.errorMessage ??
              'Workout konnte nicht gespeichert werden.',
        ),
      ),
    );
  }

  Future<void> _pickWorkoutDateTime() async {
    final workoutSession = context.read<WorkoutSessionProvider>();
    final currentDate = workoutSession.startedAt ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDate),
    );

    if (selectedTime == null) {
      return;
    }

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (selectedDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das Workout-Datum darf nicht in der Zukunft liegen.'),
        ),
      );
      return;
    }

    workoutSession.setManualWorkoutDate(selectedDateTime);
  }

  Future<void> _pickDuration() async {
    final workoutSession = context.read<WorkoutSessionProvider>();
    final durationController = TextEditingController(
      text: workoutSession.elapsed.inMinutes.toString(),
    );

    final shouldSave =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Dauer festlegen'),
              content: TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minuten',
                  suffixText: 'min',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldSave) {
      return;
    }

    final minutes = int.tryParse(durationController.text.trim()) ?? 60;
    workoutSession.setManualDuration(Duration(minutes: minutes.clamp(1, 600)));
  }

  @override
  Widget build(BuildContext context) {
    final workoutSession = context.watch<WorkoutSessionProvider>();
    final theme = Theme.of(context);
    final elapsed = workoutSession.elapsed;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final startedAt = workoutSession.startedAt;
    final localizations = MaterialLocalizations.of(context);

    if (_nameController.text != workoutSession.workoutName) {
      _nameController.text = workoutSession.workoutName;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          workoutSession.isManualEntry
              ? 'Workout nachtragen'
              : 'Active Workout Tracker',
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ElevatedButton.icon(
            onPressed: workoutSession.isSaving ? null : _finishWorkout,
            icon: workoutSession.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              workoutSession.isManualEntry
                  ? 'Workout speichern'
                  : 'Workout beenden',
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (workoutSession.isManualEntry)
                  Text(
                    startedAt == null
                        ? 'Datum waehlen'
                        : localizations.formatFullDate(startedAt),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    '$hours:$minutes:$seconds',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  workoutSession.isManualEntry
                      ? 'Trage ein Workout fuer ein bestimmtes vergangenes Datum nach.'
                      : 'Laufende Session mit Live-Timer und frei editierbaren Saetzen.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
                if (workoutSession.isManualEntry) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        onPressed: _pickWorkoutDateTime,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          startedAt == null
                              ? 'Datum und Uhrzeit'
                              : '${localizations.formatMediumDate(startedAt)} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(startedAt))}',
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        onPressed: _pickDuration,
                        icon: const Icon(Icons.schedule_rounded),
                        label: Text('${workoutSession.elapsed.inMinutes} min'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Workout-Name',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                  onChanged: workoutSession.setWorkoutName,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: _workoutTypes.map((type) {
                    return ChoiceChip(
                      label: Text(type),
                      selected: type == workoutSession.workoutType,
                      onSelected: (_) => workoutSession.setWorkoutType(type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
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
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _openExercisePicker,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Uebung hinzufuegen'),
          ),
          const SizedBox(height: 18),
          if (workoutSession.exercises.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Fuege jetzt deine erste Uebung hinzu. Danach kannst du beliebig viele Satz-Zeilen anlegen und abhaken.',
                ),
              ),
            )
          else
            ...workoutSession.exercises.asMap().entries.map((entry) {
              final exerciseIndex = entry.key;
              final trackedExercise = entry.value;

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trackedExercise.exercise.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(trackedExercise.exercise.muscleGroup),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                workoutSession.removeExercise(exerciseIndex);
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...trackedExercise.sets.asMap().entries.map((setEntry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _WorkoutSetEditor(
                              key: ValueKey(
                                '${trackedExercise.exercise.id}-${setEntry.key}',
                              ),
                              setNumber: setEntry.key + 1,
                              workoutSet: setEntry.value,
                              onWeightChanged: (value) {
                                workoutSession.updateSetWeight(
                                  exerciseIndex,
                                  setEntry.key,
                                  value,
                                );
                              },
                              onRepsChanged: (value) {
                                workoutSession.updateSetReps(
                                  exerciseIndex,
                                  setEntry.key,
                                  value,
                                );
                              },
                              onCompletedChanged: (value) {
                                workoutSession.toggleSetCompleted(
                                  exerciseIndex,
                                  setEntry.key,
                                  value,
                                );
                              },
                              onDelete: () {
                                workoutSession.removeSet(
                                  exerciseIndex,
                                  setEntry.key,
                                );
                              },
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => workoutSession.addSet(exerciseIndex),
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

class _WorkoutSetEditor extends StatefulWidget {
  const _WorkoutSetEditor({
    super.key,
    required this.setNumber,
    required this.workoutSet,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onCompletedChanged,
    required this.onDelete,
  });

  final int setNumber;
  final TrackedWorkoutSet workoutSet;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onRepsChanged;
  final ValueChanged<bool> onCompletedChanged;
  final VoidCallback onDelete;

  @override
  State<_WorkoutSetEditor> createState() => _WorkoutSetEditorState();
}

class _WorkoutSetEditorState extends State<_WorkoutSetEditor> {
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
  void didUpdateWidget(covariant _WorkoutSetEditor oldWidget) {
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
          Checkbox(
            value: widget.workoutSet.isCompleted,
            onChanged: (value) => widget.onCompletedChanged(value ?? false),
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
