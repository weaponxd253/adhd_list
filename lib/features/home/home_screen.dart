// lib/features/home/home_screen.dart
import 'package:adhd_list/features/dashboard/dashboard_screen.dart';
import 'package:adhd_list/features/mood_tracker/mood_tracker_screen.dart';
import 'package:adhd_list/features/task_breakdown/task_screen.dart';
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
    TaskScreen(),
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
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mood),
            label: 'Mood Tracker',
          ),
        ],
      ),
    );
  }
}
