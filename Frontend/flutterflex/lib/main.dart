import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/exercises_provider.dart';
import 'providers/workout_history_provider.dart';
import 'providers/workout_session_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/exercise_service.dart';
import 'services/workout_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appSettingsProvider = AppSettingsProvider();
  await appSettingsProvider.loadSettings();

  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>(create: (_) => AuthService(apiService)),
        Provider<DashboardService>(create: (_) => DashboardService(apiService)),
        Provider<ExerciseService>(create: (_) => ExerciseService(apiService)),
        Provider<WorkoutService>(create: (_) => WorkoutService(apiService)),
        ChangeNotifierProvider.value(value: appSettingsProvider),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
            context.read<AppSettingsProvider>(),
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              DashboardProvider(context.read<DashboardService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ExercisesProvider(context.read<ExerciseService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              WorkoutHistoryProvider(context.read<WorkoutService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              WorkoutSessionProvider(context.read<WorkoutService>()),
        ),
      ],
      child: const FlutterFlexApp(),
    ),
  );
}

class FlutterFlexApp extends StatelessWidget {
  const FlutterFlexApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettingsProvider>();

    return MaterialApp(
      title: 'FlutterFlex',
      debugShowCheckedModeBanner: false,
      theme: appSettings.currentThemeData,
      darkTheme: appSettings.currentDarkThemeData,
      themeMode: appSettings.themeMode,
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    return const MainNavigationScreen();
  }
}
