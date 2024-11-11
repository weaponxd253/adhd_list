// lib/models/subtask.dart
class Subtask {
  final String title;
  bool isCompleted;

  Subtask({
    required this.title,
    this.isCompleted = false,
  });
}
