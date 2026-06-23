// lib/features/tracker/tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_state.dart';
import '../../models/task.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskState>(
      builder: (context, taskState, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Habit Tracker")),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PointsDisplay(points: taskState.totalPoints),
              const SizedBox(height: 8),
              _StatsRow(
                completedTasks: taskState.completedTasks,
                completedSubtasks: taskState.completedSubtasks,
                pendingTasks: taskState.pendingTasks,
              ),
              const SizedBox(height: 24),
              _ProgressSection(taskState: taskState),
              const SizedBox(height: 24),
              _CompletedTaskList(tasks: taskState.completedTaskList),
            ],
          ),
        );
      },
    );
  }
}

// ----------------------------------------
// Points Banner
// ----------------------------------------

class _PointsDisplay extends StatelessWidget {
  final int points;
  const _PointsDisplay({required this.points});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Points",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  "$points pts",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  "10 pts per task · 5 pts per subtask",
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------
// Stats Row
// ----------------------------------------

class _StatsRow extends StatelessWidget {
  final int completedTasks;
  final int completedSubtasks;
  final int pendingTasks;

  const _StatsRow({
    required this.completedTasks,
    required this.completedSubtasks,
    required this.pendingTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.check_circle,
          label: "Tasks Done",
          value: "$completedTasks",
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.checklist,
          label: "Subtasks Done",
          value: "$completedSubtasks",
          color: Colors.teal,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.pending,
          label: "Pending",
          value: "$pendingTasks",
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------
// Progress + Streak Section
// ----------------------------------------

class _ProgressSection extends StatelessWidget {
  final TaskState taskState;
  const _ProgressSection({required this.taskState});

  @override
  Widget build(BuildContext context) {
    final total = taskState.totalTasks;
    final completed = taskState.completedTasks;
    final progress = total == 0 ? 0.0 : completed / total;
    final streak = taskState.currentStreak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Overall Progress",
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                Container(
                  height: 14,
                  width: progress * constraints.maxWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(
                      colors: [Colors.green[300]!, Colors.green[700]!],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          total == 0 ? "No tasks yet" : "$completed of $total tasks completed",
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        _StreakBanner(streak: streak),
      ],
    );
  }
}

// ----------------------------------------
// Streak Banner
// ----------------------------------------

class _StreakBanner extends StatelessWidget {
  final int streak;
  const _StreakBanner({required this.streak});

  String get _label {
    if (streak == 0)
      return "No active streak — complete a task today to start one!";
    if (streak == 1) return "1 day streak — great start, keep going!";
    if (streak < 7) return "$streak day streak — you're building momentum!";
    if (streak < 30) return "$streak day streak — on fire! 🔥";
    return "$streak day streak — legendary! 🏆";
  }

  Color get _bannerColor {
    if (streak == 0) return Colors.grey.shade100;
    if (streak < 3) return Colors.orange.shade50;
    if (streak < 7) return Colors.orange.shade100;
    return Colors.deepOrange.shade100;
  }

  Color get _borderColor {
    if (streak == 0) return Colors.grey.shade300;
    if (streak < 3) return Colors.orange.shade200;
    if (streak < 7) return Colors.orange.shade400;
    return Colors.deepOrange.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: _bannerColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Text(
            streak == 0 ? "💤" : "🔥",
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak == 0 ? "No streak" : "$streak day streak",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: streak == 0 ? Colors.black45 : Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _label,
                  style: TextStyle(
                    fontSize: 12,
                    color: streak == 0 ? Colors.black38 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------
// Completed Task List
// ----------------------------------------

class _CompletedTaskList extends StatelessWidget {
  final List<Task> tasks;
  const _CompletedTaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Completed Tasks",
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const Text(
            "No completed tasks yet. Keep going!",
            style: TextStyle(color: Colors.black45),
          )
        else
          ...tasks.map(
            (task) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(
                task.title,
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.black54,
                ),
              ),
              subtitle: _buildSubtitle(task),
            ),
          ),
      ],
    );
  }

  Widget? _buildSubtitle(Task task) {
    final completedCount = task.subtasks.where((s) => s.isCompleted).length;
    final parts = <String>[];

    if (task.subtasks.isNotEmpty) {
      parts.add("$completedCount/${task.subtasks.length} subtasks");
    }
    if (task.completedAt != null) {
      final d = task.completedAt!;
      parts.add(
          "Done ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}");
    }

    if (parts.isEmpty) return null;
    return Text(parts.join(" · "), style: const TextStyle(fontSize: 12));
  }
}
