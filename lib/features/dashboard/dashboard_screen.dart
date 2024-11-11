// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For formatting dates
import '../../providers/app_state.dart';
import '../tracker/mood_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isUpcomingTasksExpanded = false; // To manage expandable section

  // Calculates a countdown for task due dates
  String _calculateCountdown(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    if (difference < 0) return "Overdue";
    if (difference == 0) return "Due Today";
    if (difference == 1) return "Due Tomorrow";
    return "Due in $difference days";
  }

  // Determines color based on mood for visual feedback
  Color _getMoodColor(String mood) {
    switch (mood) {
      case "Calm":
        return Colors.blue[100]!;
      case "Optimistic":
        return Colors.yellow[100]!;
      case "Burnt Out":
        return Colors.orange[100]!;
      case "Panicked":
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  // Suggests an action based on the current mood
  String _suggestActionBasedOnMood(String mood) {
    switch (mood) {
      case "Burnt Out":
        return "Take a short break to recharge.";
      case "Panicked":
        return "Try some deep breathing exercises.";
      case "Optimistic":
        return "Share your positivity with others!";
      default:
        return "Keep track of your mood for insights.";
    }
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
            _buildTaskOverview(appState),
            SizedBox(height: 20),

            // Expandable Upcoming Tasks Section
            _buildUpcomingTasksSection(upcomingTasks),

            SizedBox(height: 20),

            // Mood Tracker Section
            _buildMoodTrackerSection(appState),
          ],
        ),
      ),
    );
  }

  // Helper method to build the Task Overview section
  Widget _buildTaskOverview(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  // Helper method to build the Upcoming Tasks section
  Widget _buildUpcomingTasksSection(List<dynamic> upcomingTasks) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isUpcomingTasksExpanded = !_isUpcomingTasksExpanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
        ],
      ),
    );
  }

  // Mood Tracker Section with Mood Color, Message, and Suggested Action
  Widget _buildMoodTrackerSection(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mood Tracker",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getMoodColor(appState.selectedMood),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              SizedBox(height: 8),
              Text(
                _suggestActionBasedOnMood(appState.selectedMood),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MoodHistoryScreen()),
                  );
                },
                child: Text("View Mood History"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build task status icon with label and count
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
