import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/dashboard_summary.dart';
import '../../models/workout_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/workout_history_provider.dart';
import '../workout/workout_tracker_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadSummary();
    });
  }

  Future<void> _openWorkoutTracker() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WorkoutTrackerScreen()),
    );

    if (!mounted) {
      return;
    }

    await context.read<DashboardProvider>().loadSummary();
    if (!mounted) {
      return;
    }
    await context.read<WorkoutHistoryProvider>().loadWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: dashboardProvider.loadSummary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (dashboardProvider.isLoading &&
                dashboardProvider.summary == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (dashboardProvider.summary != null) ...[
              _HeroKpiCard(
                summary: dashboardProvider.summary!,
                onPressed: _openWorkoutTracker,
              ),
              const SizedBox(height: 20),
              _ActivityCard(summary: dashboardProvider.summary!),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Letzte Workouts',
                actionLabel: 'Training starten',
                onActionPressed: _openWorkoutTracker,
              ),
              const SizedBox(height: 12),
              ...dashboardProvider.summary!.recentWorkouts.map(
                (workout) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecentWorkoutTile(workout: workout),
                ),
              ),
            ] else ...[
              const SizedBox(height: 120),
              Icon(
                Icons.signal_wifi_connected_no_internet_4_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                dashboardProvider.errorMessage ??
                    'Dashboard-Daten konnten nicht geladen werden.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroKpiCard extends StatelessWidget {
  const _HeroKpiCard({required this.summary, required this.onPressed});

  final DashboardSummary summary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Willkommen zurueck, ${summary.greetingName}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deine Trainingszeit dieser Woche bleibt auf Premium-Kurs.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _KpiValue(
                  label: 'Wochenzeit',
                  value: _formatMinutes(summary.weeklyMinutes),
                ),
              ),
              Expanded(
                child: _KpiValue(
                  label: 'Workouts',
                  value: summary.weeklyWorkouts.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.primary,
            ),
            onPressed: onPressed,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Training starten'),
          ),
        ],
      ),
    );
  }
}

String _formatMinutes(double minutes) {
  final totalMinutes = minutes.round();
  final hours = totalMinutes ~/ 60;
  final remainingMinutes = totalMinutes % 60;
  if (hours == 0) {
    return '${remainingMinutes}m';
  }
  return '${hours}h ${remainingMinutes}m';
}

class _KpiValue extends StatelessWidget {
  const _KpiValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.74),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = summary.activitySeries.fold<double>(
      1,
      (currentMax, point) =>
          point.totalMinutes > currentMax ? point.totalMinutes : currentMax,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktivitaet der letzten 7 Tage',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: summary.activitySeries.map((point) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${point.totalMinutes.toStringAsFixed(0)}m',
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            height: ((point.totalMinutes / maxValue) * 110) < 10
                                ? 10
                                : ((point.totalMinutes / maxValue) * 110),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(point.label),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(onPressed: onActionPressed, child: Text(actionLabel)),
      ],
    );
  }
}

class _RecentWorkoutTile extends StatelessWidget {
  const _RecentWorkoutTile({required this.workout});

  final WorkoutModel workout;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy, HH:mm');

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          child: Text(
            workout.workoutType.isEmpty ? '?' : workout.workoutType[0],
          ),
        ),
        title: Text(workout.name),
        subtitle: Text(
          '${dateFormat.format(workout.startTime)}  |  ${workout.totalSets} Saetze',
        ),
        trailing: Text('${workout.totalVolume.toStringAsFixed(0)} kg'),
      ),
    );
  }
}
