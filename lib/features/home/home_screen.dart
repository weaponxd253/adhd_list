// lib/features/home/home_screen.dart
import 'package:adhd_list/features/dashboard/dashboard_screen.dart';
import 'package:adhd_list/features/mood_tracker/mood_tracker_screen.dart';
import 'package:adhd_list/features/task_breakdown/task_screen.dart'; // Import TaskScreen
import 'package:adhd_list/features/timer/timer_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // List of screens to show for each tab
  final List<Widget> _screens = [
    DashboardScreen(),
    TaskScreen(),  // Use TaskScreen in the tabs
    TimerScreen(),
    MoodTrackerScreen(),
  ];

  // Update the selected index and refresh the UI
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Allows four or more items
        items: const [
    BottomNavigationBarItem(
      icon: Tooltip(
        message: 'Dashboard - View your tasks and progress', // Tooltip for Dashboard
        child: Icon(Icons.dashboard),
      ),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Tooltip(
        message: 'Tasks - Manage your tasks here', // Tooltip for Tasks
        child: Icon(Icons.task),
      ),
      label: 'Tasks',
    ),
    BottomNavigationBarItem(
      icon: Tooltip(
        message: 'Timer - Focus using Pomodoro Timer', // Tooltip for Timer
        child: Icon(Icons.timer),
      ),
      label: 'Timer',
    ),
    BottomNavigationBarItem(
      icon: Tooltip(
        message: 'Mood Tracker - Track your daily mood', // Tooltip for Mood Tracker
        child: Icon(Icons.mood),
      ),
      label: 'Mood',
    ),
        ],
      ),
    );
  }
}
