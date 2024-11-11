// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FocusFlow Dashboard")),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                "Productivity Chart Placeholder",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                "Mood Tracker Placeholder",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tasks'); // Navigate to TaskScreen
              },
              child: Text("Go to Tasks"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/timer'); // Navigate to TimerScreen
              },
              child: Text("Go to Timer"),
            ),
          ),
        ],
      ),
    );
  }
}
