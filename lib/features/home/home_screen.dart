import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../mood_tracker/mood_tracker_screen.dart';
import '../task_breakdown/task_screen.dart';
import '../timer/timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      key: Key('navigation-home'),
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
      tooltip: 'Home dashboard',
    ),
    NavigationDestination(
      key: Key('navigation-tasks'),
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist_rounded),
      label: 'Tasks',
      tooltip: 'Tasks',
    ),
    NavigationDestination(
      key: Key('navigation-timer'),
      icon: Icon(Icons.timer_outlined),
      selectedIcon: Icon(Icons.timer_rounded),
      label: 'Timer',
      tooltip: 'Focus timer',
    ),
    NavigationDestination(
      key: Key('navigation-mood'),
      icon: Icon(Icons.mood_outlined),
      selectedIcon: Icon(Icons.mood_rounded),
      label: 'Mood',
      tooltip: 'Mood tracker',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onOpenMood: () => setState(() => _selectedIndex = 3),
        onOpenTimer: () => setState(() => _selectedIndex = 2),
      ),
      const TaskScreen(),
      const TimerScreen(),
      const MoodTrackerScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top:
                BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            key: const Key('primary-navigation'),
            selectedIndex: _selectedIndex,
            destinations: _destinations,
            onDestinationSelected: (index) {
              if (index == _selectedIndex) return;
              setState(() => _selectedIndex = index);
            },
          ),
        ),
      ),
    );
  }
}
