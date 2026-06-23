import 'subtask.dart';

class Task {
  final int id;
  final String title;
  final DateTime dueDate;
  String status; // "pending", "in_progress", "completed"
  List<Subtask> subtasks;

  // Set when status transitions to 'completed'. Null for tasks that were
  // completed before v4 of the DB schema (which added the completed_at column).
  DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.status = "pending",
    this.completedAt,
    List<Subtask>? subtasks,
  }) : subtasks = subtasks ?? [];

  bool get isCompleted => status == "completed";
}
