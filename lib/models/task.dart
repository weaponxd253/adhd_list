import 'subtask.dart';

class Task {
  final int id;
  final String title;
  final DateTime dueDate;
  String status; // "pending", "in_progress", "completed"
  List<Subtask> subtasks; // 
  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.status = "pending",
    List<Subtask>? subtasks, // 
  }) : subtasks = subtasks ?? []; // Ensure it's always a list

  bool get isCompleted => status == "completed"; // 
}
