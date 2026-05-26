// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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
        title: const Text("FocusFlow Dashboard"),
        actions: [
          IconButton(
            icon: Icon(
              appState.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: 'Switch between Light and Dark Theme',
            onPressed: appState.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskOverview(),
              const SizedBox(height: 20),
              _buildUpcomingTasksSection(appState.upcomingTasks),
              const SizedBox(height: 20),
              _buildMoodTrackerSection(),
              const SizedBox(height: 20),
              _buildTimerSection(appState),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  appState.clearTaskHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All task history cleared")),
                  );
                },
                child: const Text("Clear Task History"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  appState.clearMoodHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All mood history cleared")),
                  );
                },
                child: const Text("Clear Mood History"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Timer section ----

  Widget _buildTimerSection(AppState appState) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pomodoro Timer",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Current Mode: ${appState.currentMode}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 10),
            Text("Remaining Time: ${appState.timerDisplay}",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: appState.isTimerRunning
                      ? appState.pauseTimer
                      : () => appState.startTimer(
                          appState.currentMode == "Focus"),
                  child:
                      Text(appState.isTimerRunning ? "Pause" : "Start"),
                ),
                ElevatedButton(
                  onPressed: appState.resetTimer,
                  child: const Text("Reset"),
                ),
                ElevatedButton(
                  onPressed: appState.switchToNextMode,
                  child: const Text("Switch Mode"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Task overview ----

  Widget _buildTaskOverview() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final progress = appState.totalTasks == 0
            ? 0.0
            : appState.completedTasks / appState.totalTasks;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Task Overview",
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTaskStatusIcon(Icons.assignment, "Total",
                    appState.totalTasks, Colors.blue),
                _buildTaskStatusIcon(Icons.check_circle, "Completed",
                    appState.completedTasks, Colors.green),
                _buildTaskStatusIcon(Icons.pending, "Pending",
                    appState.pendingTasks, Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            _buildProgressBar(progress),
          ],
        );
      },
    );
  }

  Widget _buildTaskStatusIcon(
      IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28.0),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
        Text("$count",
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ],
    );
  }

  // Fixed: uses LayoutBuilder so the fill width is relative to the actual
  // container, not the full screen width (which overflows inside padded cards).
  Widget _buildProgressBar(double progress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey[300],
          ),
          child: Stack(
            children: [
              Container(
                width: progress * constraints.maxWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    colors: [Colors.green[300]!, Colors.green[800]!],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- Upcoming tasks ----

  Widget _buildUpcomingTasksSection(List<dynamic> upcomingTasks) {
    return GestureDetector(
      onTap: () =>
          setState(() => _isUpcomingTasksExpanded = !_isUpcomingTasksExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Upcoming Tasks",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
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
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  )
                : Column(
                    children: upcomingTasks.map((task) {
                      return ListTile(
                        leading: Icon(
                          Icons.circle,
                          size: 10,
                          color:
                              task.isCompleted ? Colors.green : Colors.red,
                        ),
                        title: Text(task.title),
                        subtitle: Text(
                          "Due: ${DateFormat.yMMMd().format(task.dueDate)}"
                          " (${_calculateCountdown(task.dueDate)})",
                        ),
                      );
                    }).toList(),
                  ),
        ],
      ),
    );
  }

  String _calculateCountdown(DateTime dueDate) {
    final difference = dueDate.difference(DateTime.now()).inDays;
    if (difference < 0) return "Overdue";
    if (difference == 0) return "Due Today";
    if (difference == 1) return "Due Tomorrow";
    return "Due in $difference days";
  }

  // ---- Mood tracker ----

  Widget _buildMoodTrackerSection() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mood Tracker",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getMoodColor(appState.selectedMood, context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Current Mood: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "${appState.selectedMoodEmoji} "
                        "${appState.selectedMood.isEmpty ? "No mood selected." : appState.selectedMood}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.moodMessage,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getMoodColor(String mood, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (mood) {
      case "Calm":
        return isDark ? Colors.blue[600]! : Colors.blue[100]!;
      case "Optimistic":
        return isDark ? Colors.yellow[600]! : Colors.yellow[100]!;
      case "Burnt Out":
        return isDark ? Colors.orange[600]! : Colors.orange[100]!;
      case "Panicked":
        return isDark ? Colors.red[600]! : Colors.red[100]!;
      default:
        return isDark
            ? Colors.grey[800]!
            : Colors.orange[100]!;
    }
  }
}
