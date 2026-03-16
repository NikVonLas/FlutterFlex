import 'package:flutter/material.dart';

import 'dashboard/dashboard_screen.dart';
import 'exercises/exercises_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';
import 'statistics/statistics_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _tabTransitionController;
  late final Animation<double> _tabOpacity;
  late final Animation<Offset> _tabSlide;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const StatisticsScreen(),
    const HistoryScreen(),
    const ExercisesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();

    _tabOpacity = CurvedAnimation(
      parent: _tabTransitionController,
      curve: Curves.easeOut,
    );

    _tabSlide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _tabTransitionController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _tabTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _tabOpacity,
        child: SlideTransition(
          position: _tabSlide,
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _tabTransitionController.forward(from: 0);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.query_stats_outlined),
                selectedIcon: Icon(Icons.query_stats_rounded),
                label: 'Statistik',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'Historie',
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center_rounded),
                label: 'Uebungen',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Einstellungen',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
