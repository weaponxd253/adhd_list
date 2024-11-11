// lib/features/tracker/tracker_screen.dart
import 'package:flutter/material.dart';

class TrackerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Habit Tracker")),
      body: Column(
        children: [
          PointsDisplay(),
          StreakDisplay(),
          RecentProgress(),
        ],
      ),
    );
  }
}

class PointsDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.star),
      title: Text("Total Points: 150"),
    );
  }
}

class StreakDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.bolt),
      title: Text("Current Streak: 7 days"),
    );
  }
}

class RecentProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(title: Text("Completed Task 1")),
        ListTile(title: Text("Completed Task 2")),
      ],
    );
  }
}
