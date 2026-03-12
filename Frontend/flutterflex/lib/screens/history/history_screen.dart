import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/workout_history_provider.dart';
import '../workout/workout_tracker_screen.dart';
import '../workout/edit_workout_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> _openManualWorkoutEntry() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das ausgewaehlte Datum darf nicht in der Zukunft liegen.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkoutTrackerScreen(
          initialManualEntry: true,
          initialManualStartAt: selectedDateTime,
          initialManualDuration: const Duration(minutes: 60),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await context.read<WorkoutHistoryProvider>().loadWorkouts();
    if (!mounted) {
      return;
    }
    await context.read<DashboardProvider>().loadSummary();
  }

  Future<void> _openEditWorkout(int workoutId) async {
    final wasUpdated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditWorkoutScreen(workoutId: workoutId)),
    );

    if (wasUpdated != true || !mounted) {
      return;
    }

    await context.read<WorkoutHistoryProvider>().loadWorkouts();
    if (!mounted) {
      return;
    }
    await context.read<DashboardProvider>().loadSummary();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutHistoryProvider>().loadWorkouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<WorkoutHistoryProvider>();
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historie'),
        actions: [
          IconButton(
            tooltip: 'Workout nachtragen',
            onPressed: _openManualWorkoutEntry,
            icon: const Icon(Icons.post_add_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: historyProvider.loadWorkouts,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Alle vergangenen Trainingseinheiten live aus dem Backend.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (historyProvider.isLoading && historyProvider.workouts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (historyProvider.workouts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Noch keine Workouts gespeichert.'),
                ),
              )
            else
              ...historyProvider.workouts.map(
                (workout) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      onTap: () => _openEditWorkout(workout.id),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      title: Text(workout.name),
                      subtitle: Text(
                        '${dateFormat.format(workout.startTime)}  |  ${workout.workoutType}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          const SizedBox(height: 4),
                          Text('${workout.totalSets} Saetze'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
