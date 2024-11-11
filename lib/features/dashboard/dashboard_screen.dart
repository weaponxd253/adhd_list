// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../tracker/mood_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isUpcomingTasksExpanded = false;

  // Helper to calculate due date countdown
  String _calculateCountdown(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    if (difference < 0) return "Overdue";
    if (difference == 0) return "Due Today";
    if (difference == 1) return "Due Tomorrow";
    return "Due in $difference days";
  }

  // Helper to get mood-based color
  Color _getMoodColor(String mood) {
    switch (mood) {
      case "Calm": return Colors.blue[100]!;
      case "Optimistic": return Colors.yellow[100]!;
      case "Burnt Out": return Colors.orange[100]!;
      case "Panicked": return Colors.red[100]!;
      default: return Colors.grey[200]!;
    }
  }

  // Suggested action based on mood
  String _suggestActionBasedOnMood(String mood) {
    switch (mood) {
      case "Burnt Out": return "Take a short break to recharge.";
      case "Panicked": return "Try some deep breathing exercises.";
      case "Optimistic": return "Share your positivity with others!";
      default: return "Keep track of your mood for insights.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final upcomingTasks = appState.upcomingTasks;
    upcomingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: AppBar(title: Text("FocusFlow Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<AppState>(builder: (context, appState, child) {
                return _buildTaskOverview(appState);
              },
            child: _buildTaskOverview(appState)),
            SizedBox(height: 20),
            Consumer<AppState>(builder: (context, appState, child) {
                return _buildUpcomingTasksSection(appState.upcomingTasks);
              },
            child: _buildUpcomingTasksSection(upcomingTasks)),
            SizedBox(height: 20),
            Consumer<AppState>(builder: (context, appState, child) {
                return _buildMoodTrackerSection(appState);
              },
            child: _buildMoodTrackerSection(appState)),
          ],
        ),
      ),
    );
  }

  // Task Overview Section
// In DashboardScreen

Widget _buildTaskOverview(AppState appState) {
  return Consumer<AppState>(
    builder: (context, appState, _) {
      double progress = appState.totalTasks == 0 ? 0 : appState.completedTasks / appState.totalTasks;
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
          // Updated Progress Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: Colors.green,
            minHeight: 8,
          ),
        ],
      );
    },
  );
}


  // Upcoming Tasks Section
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
              Text("Upcoming Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(
                _isUpcomingTasksExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
            ],
          ),
          if (_isUpcomingTasksExpanded)
            Column(
              children: upcomingTasks.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          "No upcoming tasks",
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ]
                  : upcomingTasks.map((task) {
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

  // Mood Tracker Section
  Widget _buildMoodTrackerSection(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Mood Tracker", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
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

  // Task Status Icon Helper
  Widget _buildTaskStatusIcon(IconData icon, String label, int count, Color color) {
    const double iconSize = 28.0;
    const Color iconColor = Colors.blueGrey;

    return Column(
      children: [
        Icon(icon, color: iconColor, size: iconSize),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: iconColor, fontSize: 14)),
        Text("$count", style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // Progress Bar with Gradient and Shadow
  Widget _buildProgressBar(double progress) {
  return Container(
    height: 10,
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          offset: Offset(0, 2),
          blurRadius: 4.0, // 3D shadow effect
        ),
      ],
      borderRadius: BorderRadius.circular(5),
      gradient: LinearGradient(
        colors: [Colors.green[300]!, Colors.green[800]!],
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey[300],
        color: Colors.transparent, // Transparent to show gradient
      ),
    ),
  );
}

}
