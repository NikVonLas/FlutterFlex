import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/workout_history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
      appBar: AppBar(title: const Text('Historie')),
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
                          Text('${workout.totalVolume.toStringAsFixed(0)} kg'),
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
