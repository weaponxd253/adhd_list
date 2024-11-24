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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("FocusFlow Dashboard"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Overview Section
              _buildTaskOverview(appState),
              SizedBox(height: 20),

              // Upcoming Tasks Section
              _buildUpcomingTasksSection(appState.upcomingTasks),
              SizedBox(height: 20),

              // Mood Tracker Section
              _buildMoodTrackerSection(appState),
              SizedBox(height: 20),
              _buildTimerSection(appState),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildTimerSection(AppState appState) {
  return Container(
    width: double.infinity, // Ensures the card takes full width of the parent
    height: 200, // Consistent height for visual alignment
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Text(
              "Pomodoro Timer",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Current Mode: ${appState.currentMode}",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 10),
            Text(
              "Remaining Time: ${appState.timerDisplay}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Spacer(), // Push button to bottom
            ElevatedButton(
              onPressed: appState.isTimerRunning
                  ? appState.stopTimer
                  : () => appState.startTimer(appState.currentMode == "Focus"),
              child:
                  Text(appState.isTimerRunning ? "Stop Timer" : "Start Timer"),
            ),
          ],
        ),
      ),
    ),
  );
}



  // --- Task Overview Section ---
  Widget _buildTaskOverview(AppState appState) {
    double progress = appState.totalTasks == 0
        ? 0
        : appState.completedTasks / appState.totalTasks;

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
            _buildTaskStatusIcon(
                Icons.assignment, "Total", appState.totalTasks, Colors.blue),
            _buildTaskStatusIcon(Icons.check_circle, "Completed",
                appState.completedTasks, Colors.green),
            _buildTaskStatusIcon(
                Icons.pending, "Pending", appState.pendingTasks, Colors.red),
          ],
        ),
        SizedBox(height: 20),
        _buildProgressBar(progress),
      ],
    );
  }

  Widget _buildTaskStatusIcon(
      IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28.0),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
        Text(
          "$count",
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient:
            LinearGradient(colors: [Colors.green[300]!, Colors.green[800]!]),
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

  // --- Upcoming Tasks Section ---
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
                _isUpcomingTasksExpanded
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: Colors.grey,
              ),
            ],
          ),
          if (_isUpcomingTasksExpanded)
            upcomingTasks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      "No upcoming tasks",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: upcomingTasks.map((task) {
                      return ListTile(
                        leading: Icon(
                          Icons.circle,
                          size: 10,
                          color: task.isCompleted ? Colors.green : Colors.red,
                        ),
                        title: Text(task.title),
                        subtitle: Text(
                          "Due Date: ${DateFormat.yMMMd().format(task.dueDate)} (${_calculateCountdown(task.dueDate)})",
                        ),
                      );
                    }).toList(),
                  ),
        ],
      ),
    );
  }

  String _calculateCountdown(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    if (difference < 0) return "Overdue";
    if (difference == 0) return "Due Today";
    if (difference == 1) return "Due Tomorrow";
    return "Due in $difference days";
  }

  // --- Mood Tracker Section ---
 Widget _buildMoodTrackerSection(AppState appState) {
  return Container(
    height: 200, // Consistent height for uniformity
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Text(
              "Mood Tracker",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  "Current Mood: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${appState.selectedMoodEmoji} ${appState.selectedMood}",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              appState.moodMessage.isNotEmpty
                  ? appState.moodMessage
                  : "Select a mood to see a message.",
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Spacer(), // Pushes the button to the bottom
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MoodHistoryScreen(),
                  ),
                );
              },
              child: Text("View Mood History"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            ),
          ],
        ),
      ),
    ),
  );
}


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
}
