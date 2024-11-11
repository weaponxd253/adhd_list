// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'dart:math';
import '../../providers/app_state.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isUpcomingTasksExpanded = false; // To manage expandable section

  String _calculateCountdown(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    if (difference < 0) return "Overdue";
    if (difference == 0) return "Due Today";
    if (difference == 1) return "Due Tomorrow";
    return "Due in $difference days";
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final upcomingTasks = appState.upcomingTasks;
    // Sort tasks by due date (earliest first)
    upcomingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: AppBar(
        title: Text("FocusFlow Dashboard"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Overview Section
            Text(
              "Task Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTaskStatusIcon(Icons.assignment, "Total", appState.totalTasks, Colors.blue),
                _buildTaskStatusIcon(Icons.check_circle, "Completed", appState.completedTasks, Colors.green),
                _buildTaskStatusIcon(Icons.pending, "Pending", appState.pendingTasks, Colors.red),
              ],
            ),
            SizedBox(height: 20),
            // Progress Bar for Completed Tasks
            LinearProgressIndicator(
              value: appState.totalTasks == 0 ? 0 : appState.completedTasks / appState.totalTasks,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
              minHeight: 8,
            ),
            SizedBox(height: 20),
            // Expandable Upcoming Tasks Section
            GestureDetector(
              onTap: () {
                setState(() {
                  _isUpcomingTasksExpanded = !_isUpcomingTasksExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Upcoming Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    _isUpcomingTasksExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            if (_isUpcomingTasksExpanded)
              Column(
                children: upcomingTasks.map((task) {
                  final countdownText = _calculateCountdown(task.dueDate);
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: 10,
                      color: task.isCompleted ? Colors.green : Colors.red,
                    ),
                    title: Text(task.title),
                    subtitle: Text("Due Date: ${DateFormat.yMMMd().format(task.dueDate)} ($countdownText)"),
                  );
                }).toList(),
              ),
            SizedBox(height: 20),
            // Mood Tracker Section
            Text(
              "Mood Tracker",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Current Mood: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "${appState.selectedMoodEmoji} ${appState.selectedMood}",
                  style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(appState.moodMessage, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  // Helper method to build the task status icon with label and count
  Widget _buildTaskStatusIcon(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        SizedBox(height: 4),
        Text(label),
        Text(
          "$count",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
