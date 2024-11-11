// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final selectedMood = appState.selectedMood;
    final selectedMoodEmoji = appState.selectedMoodEmoji;
    final moodMessage = appState.moodMessage;

    // Retrieve task overview data
    final totalTasks = appState.totalTasks;
    final completedTasks = appState.completedTasks;
    final pendingTasks = appState.pendingTasks;
    final upcomingTasks = appState.upcomingTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text("FocusFlow Dashboard"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Task Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),
            Text(
              "Total Tasks: $totalTasks",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            Text(
              "Completed Tasks: $completedTasks",
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
            Text(
              "Pending Tasks: $pendingTasks",
              style: TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
            SizedBox(height: 20),

            if (upcomingTasks.isNotEmpty) 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Upcoming Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...upcomingTasks.map((task) => ListTile(
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text("Due soon"),
                  )),
                ],
              )
            else
              Text(
                "No upcoming tasks",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

            SizedBox(height: 20),
            
            Text(
              "Mood Tracker",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            SizedBox(height: 10),
            if (selectedMood.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Current Mood: ",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "$selectedMoodEmoji $selectedMood",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    moodMessage,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              )
            else
              Text(
                "No mood selected",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
