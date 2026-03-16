import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/workout_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/workout_history_provider.dart';
import '../../widgets/reveal_on_load.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutHistoryProvider>().loadWorkouts();
    });
  }

  Future<void> _editGoals(BuildContext context) async {
    final appSettings = context.read<AppSettingsProvider>();
    final workoutGoalController = TextEditingController(
      text: appSettings.weeklyWorkoutGoal.toString(),
    );
    final volumeGoalController = TextEditingController(
      text: appSettings.weeklyVolumeGoal.toStringAsFixed(0),
    );

    final shouldSave =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Woechentliche Ziele'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: workoutGoalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Workout-Ziel pro Woche',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: volumeGoalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Volumen-Ziel pro Woche (kg)',
                    ),
                  ),
                ],
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

    if (!shouldSave || !context.mounted) {
      return;
    }

    final workoutGoal =
        int.tryParse(workoutGoalController.text.trim()) ??
        appSettings.weeklyWorkoutGoal;
    final volumeGoal =
        double.tryParse(
          volumeGoalController.text.trim().replaceAll(',', '.'),
        ) ??
        appSettings.weeklyVolumeGoal;

    await appSettings.setWeeklyGoals(
      workoutGoal: math.max(1, workoutGoal),
      volumeGoal: math.max(100, volumeGoal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<WorkoutHistoryProvider>();
    final appSettings = context.watch<AppSettingsProvider>();
    final weeklyStats = _WeeklyStats.fromWorkouts(historyProvider.workouts);
    final totalVolume = historyProvider.workouts.fold<double>(
      0,
      (sum, workout) => sum + workout.totalVolume,
    );
    final totalSets = historyProvider.workouts.fold<int>(
      0,
      (sum, workout) => sum + workout.totalSets,
    );
    final averageVolume = historyProvider.workouts.isEmpty
        ? 0.0
        : totalVolume / historyProvider.workouts.length;
    final safeWorkoutGoal = appSettings.weeklyWorkoutGoal < 1
        ? 1
        : appSettings.weeklyWorkoutGoal;
    final safeVolumeGoal =
        (appSettings.weeklyVolumeGoal <= 0 ? 100 : appSettings.weeklyVolumeGoal)
            .toDouble();
    final workoutGoalProgress = weeklyStats.workoutCount / safeWorkoutGoal;
    final volumeGoalProgress = weeklyStats.totalVolume / safeVolumeGoal;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiken')),
      body: RefreshIndicator(
        onRefresh: historyProvider.loadWorkouts,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (historyProvider.isLoading && historyProvider.workouts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              RevealOnLoad(
                child: _GoalProgressCard(
                  weeklyStats: weeklyStats,
                  workoutGoal: safeWorkoutGoal,
                  volumeGoal: safeVolumeGoal,
                  workoutGoalProgress: workoutGoalProgress,
                  volumeGoalProgress: volumeGoalProgress,
                  onEditPressed: () => _editGoals(context),
                ),
              ),
              const SizedBox(height: 16),
              RevealOnLoad(
                delay: const Duration(milliseconds: 90),
                child: _MetricsGrid(
                  totalWorkouts: historyProvider.workouts.length,
                  totalVolume: totalVolume,
                  totalSets: totalSets,
                  averageVolume: averageVolume,
                ),
              ),
              const SizedBox(height: 16),
              RevealOnLoad(
                delay: const Duration(milliseconds: 170),
                child: _VolumeTrendCard(workouts: historyProvider.workouts),
              ),
              const SizedBox(height: 16),
              RevealOnLoad(
                delay: const Duration(milliseconds: 250),
                child: _WorkoutTypeDonutCard(
                  workouts: historyProvider.workouts,
                  primaryColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const RevealOnLoad(
                delay: Duration(milliseconds: 320),
                child: _MuscleGroupCard(),
              ),
              if (historyProvider.errorMessage != null &&
                  historyProvider.workouts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  historyProvider.errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  const _GoalProgressCard({
    required this.weeklyStats,
    required this.workoutGoal,
    required this.volumeGoal,
    required this.workoutGoalProgress,
    required this.volumeGoalProgress,
    required this.onEditPressed,
  });

  final _WeeklyStats weeklyStats;
  final int workoutGoal;
  final double volumeGoal;
  final double workoutGoalProgress;
  final double volumeGoalProgress;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Woechentliche Ziele',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEditPressed,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${weeklyStats.workoutCount} von $workoutGoal Workouts erreicht',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: workoutGoalProgress.clamp(0, 1)),
            const SizedBox(height: 16),
            Text(
              '${weeklyStats.totalVolume.toStringAsFixed(0)} von ${volumeGoal.toStringAsFixed(0)} kg Volumen erreicht',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: volumeGoalProgress.clamp(0, 1)),
            const SizedBox(height: 14),
            Text(
              weeklyStats.workoutCount >= workoutGoal &&
                      weeklyStats.totalVolume >= volumeGoal
                  ? 'Alle Wochenziele fuer diese Woche erreicht.'
                  : 'Passe die Ziele an deinen Trainingsrhythmus an.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.totalWorkouts,
    required this.totalVolume,
    required this.totalSets,
    required this.averageVolume,
  });

  final int totalWorkouts;
  final double totalVolume;
  final int totalSets;
  final double averageVolume;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Gesamt-Workouts', totalWorkouts.toString()),
      ('Gesamtvolumen', '${totalVolume.toStringAsFixed(0)} kg'),
      ('Gesamt-Saetze', totalSets.toString()),
      ('Ø Volumen', '${averageVolume.toStringAsFixed(0)} kg'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(card.$1, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  card.$2,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VolumeTrendCard extends StatelessWidget {
  const _VolumeTrendCard({required this.workouts});

  final List<WorkoutModel> workouts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = _buildSeries(workouts);
    final maxValue = series.fold<double>(
      1,
      (currentMax, point) =>
          point.volume > currentMax ? point.volume : currentMax,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volumentrend der letzten 7 Tage',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: series.map((point) {
                  final barHeight = math
                      .max(10, (point.volume / maxValue) * 125)
                      .toDouble();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            point.volume.toStringAsFixed(0),
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
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

  List<_TrendPoint> _buildSeries(List<WorkoutModel> workouts) {
    final cutoff = DateTime.now().subtract(const Duration(days: 6));
    final dailyTotals = <String, double>{};

    for (final workout in workouts) {
      if (workout.startTime.isBefore(
        DateTime(cutoff.year, cutoff.month, cutoff.day),
      )) {
        continue;
      }

      final key = DateFormat('yyyy-MM-dd').format(workout.startTime);
      dailyTotals[key] = (dailyTotals[key] ?? 0) + workout.totalVolume;
    }

    return List<_TrendPoint>.generate(7, (index) {
      final day = DateTime.now().subtract(Duration(days: 6 - index));
      final key = DateFormat('yyyy-MM-dd').format(day);
      return _TrendPoint(
        label: DateFormat('EE', 'de_DE').format(day),
        volume: dailyTotals[key] ?? 0,
      );
    });
  }
}

class _WeeklyStats {
  const _WeeklyStats({required this.workoutCount, required this.totalVolume});

  final int workoutCount;
  final double totalVolume;

  factory _WeeklyStats.fromWorkouts(List<WorkoutModel> workouts) {
    final weekStart = DateTime.now().subtract(const Duration(days: 7));
    final weeklyWorkouts = workouts
        .where((workout) => workout.startTime.isAfter(weekStart))
        .toList();

    return _WeeklyStats(
      workoutCount: weeklyWorkouts.length,
      totalVolume: weeklyWorkouts.fold<double>(
        0,
        (sum, workout) => sum + workout.totalVolume,
      ),
    );
  }
}

class _TrendPoint {
  const _TrendPoint({required this.label, required this.volume});

  final String label;
  final double volume;
}

class _WorkoutTypeDonutCard extends StatelessWidget {
  const _WorkoutTypeDonutCard({
    required this.workouts,
    required this.primaryColor,
  });

  final List<WorkoutModel> workouts;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distribution = _buildDistribution(primaryColor: primaryColor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout-Typ Verteilung',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            if (distribution.isEmpty)
              const Text('Noch keine Workouts fuer die Verteilung vorhanden.')
            else
              Row(
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: _DonutChartPainter(segments: distribution),
                      child: Center(
                        child: Text(
                          '${workouts.length}\nWorkouts',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: distribution.map((segment) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: segment.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(segment.label)),
                              Text('${segment.percentage.toStringAsFixed(0)}%'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<_DonutSegment> _buildDistribution({required Color primaryColor}) {
    if (workouts.isEmpty) return const [];

    final byType = <String, int>{};
    for (final workout in workouts) {
      final type = workout.workoutType.trim().isEmpty
          ? 'Unbekannt'
          : workout.workoutType.trim();
      byType[type] = (byType[type] ?? 0) + 1;
    }

    final count = byType.length.clamp(3, 8);
    final palette = _buildThemePalette(primaryColor, count);

    final sorted = byType.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    final total = workouts.length;
    return sorted.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return _DonutSegment(
        label: item.key,
        value: item.value.toDouble(),
        percentage: (item.value / total) * 100,
        color: palette[index % palette.length],
      );
    }).toList();
  }
}

class _DonutSegment {
  const _DonutSegment({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double value;
  final double percentage;
  final Color color;
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.segments});

  final List<_DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
    if (total <= 0) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 4);

    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = (segment.value / total) * (math.pi * 2);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 20;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

List<Color> _buildThemePalette(Color primary, int count) {
  final hsl = HSLColor.fromColor(primary);
  final s = (hsl.saturation * 0.9).clamp(0.45, 0.85);
  return List.generate(count, (i) {
    final hue = (hsl.hue + i * (360.0 / count)) % 360;
    final l = i.isEven ? 0.50 : 0.63;
    return HSLColor.fromAHSL(1.0, hue, s, l).toColor();
  });
}

class _MuscleGroupCard extends StatefulWidget {
  const _MuscleGroupCard();

  @override
  State<_MuscleGroupCard> createState() => _MuscleGroupCardState();
}

class _MuscleGroupCardState extends State<_MuscleGroupCard> {
  int? _days = 30;
  late Future<List<MuscleGroupStat>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MuscleGroupStat>> _load() =>
      context.read<WorkoutHistoryProvider>().fetchMuscleGroupStats(days: _days);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Muskelgruppen-Analyse',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int?>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 Tage')),
                  ButtonSegment(value: 30, label: Text('30 Tage')),
                  ButtonSegment(value: 90, label: Text('90 Tage')),
                  ButtonSegment(value: null, label: Text('Gesamt')),
                ],
                selected: {_days},
                onSelectionChanged: (selection) {
                  setState(() {
                    _days = selection.first;
                    _future = _load();
                  });
                },
              ),
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<MuscleGroupStat>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final stats = snapshot.data ?? [];
                if (stats.isEmpty) {
                  return const Text(
                    'Keine Daten fuer den gewaehlten Zeitraum vorhanden.\n'
                    'Tracke Workouts mit Uebungen, um Analysen zu sehen.',
                  );
                }
                final maxCount = stats.first.workoutCount;
                return Column(
                  children: stats.map((stat) {
                    final ratio = stat.workoutCount / maxCount;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stat.muscleGroup,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${stat.workoutCount}x',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 10,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
