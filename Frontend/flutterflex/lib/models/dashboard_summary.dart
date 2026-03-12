import 'workout_model.dart';

class ActivityPoint {
  const ActivityPoint({required this.label, required this.totalMinutes});

  final String label;
  final double totalMinutes;

  factory ActivityPoint.fromJson(Map<String, dynamic> json) {
    return ActivityPoint(
      label: json['label'] as String,
      totalMinutes:
          double.tryParse((json['totalMinutes'] ?? 0).toString()) ?? 0,
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.greetingName,
    required this.weeklyMinutes,
    required this.weeklyWorkouts,
    required this.activitySeries,
    required this.recentWorkouts,
  });

  final String greetingName;
  final double weeklyMinutes;
  final int weeklyWorkouts;
  final List<ActivityPoint> activitySeries;
  final List<WorkoutModel> recentWorkouts;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      greetingName: (json['greetingName'] ?? 'Athlete') as String,
      weeklyMinutes:
          double.tryParse((json['weeklyMinutes'] ?? 0).toString()) ?? 0,
      weeklyWorkouts:
          int.tryParse((json['weeklyWorkouts'] ?? 0).toString()) ?? 0,
      activitySeries: (json['activitySeries'] as List<dynamic>? ?? [])
          .map((entry) => ActivityPoint.fromJson(entry as Map<String, dynamic>))
          .toList(),
      recentWorkouts: (json['recentWorkouts'] as List<dynamic>? ?? [])
          .map((entry) => WorkoutModel.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }
}
