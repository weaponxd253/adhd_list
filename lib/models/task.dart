// lib/models/task.dart
import 'subtask.dart';

class Task {
  final String title;
  final DateTime dueDate;
  bool isCompleted;
  List<Subtask> subtasks; // Make sure this is a modifiable list

  Task({
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
    List<Subtask>? subtasks,
  }) : subtasks = subtasks ?? []; // Initialize as a modifiable empty list if null
}
