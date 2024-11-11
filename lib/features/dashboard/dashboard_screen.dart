// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FocusFlow Dashboard")),
      body: Column(
        children: [
          ProductivityChart(),
          MoodTracker(),
        ],
      ),
    );
  }
}

class ProductivityChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.blueGrey.shade50,
      child: Center(child: Text("Productivity Chart Placeholder")),
    );
  }
}

class MoodTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.green.shade50,
      child: Center(child: Text("Mood Tracker Placeholder")),
    );
  }
}
