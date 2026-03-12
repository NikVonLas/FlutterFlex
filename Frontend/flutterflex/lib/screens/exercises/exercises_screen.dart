import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/exercises_provider.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExercisesProvider>().loadExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercisesProvider = context.watch<ExercisesProvider>();
    final exercises = exercisesProvider.exercises;

    return Scaffold(
      appBar: AppBar(title: const Text('Uebungs-Bibliothek')),
      body: RefreshIndicator(
        onRefresh: exercisesProvider.loadExercises,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Nach Uebung suchen',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: exercisesProvider.setSearchQuery,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: exercisesProvider.muscleGroups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final group = exercisesProvider.muscleGroups[index];
                  return ChoiceChip(
                    label: Text(group),
                    selected: group == exercisesProvider.selectedMuscleGroup,
                    onSelected: (_) {
                      exercisesProvider.setSelectedMuscleGroup(group);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (exercisesProvider.isLoading && exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercises.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.fitness_center_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            exercise.muscleGroup,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            exercise.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
