// lib/providers/app_state.dart
import 'package:flutter/material.dart';
import 'dart:async';

class Subtask {
  String title;
  bool isCompleted;

  Subtask({required this.title, this.isCompleted = false});
}

class Task {
  final String title;
  List<Subtask> subtasks; // Ensure this is always List<Subtask>
  bool isCompleted;

  Task({required this.title, this.subtasks = const [], this.isCompleted = false});
}

class AppState extends ChangeNotifier {
  List<Task> tasks = [];
  bool isTimerRunning = false;
  int workDuration = 25; // Default work duration in minutes
  int breakDuration = 5; // Default break duration in minutes
  Timer? _timer;
  int remainingTime = 0; // Remaining time in seconds

  // Add a new task with an empty List<Subtask>
  void addTask(String taskTitle) {
    tasks.add(Task(title: taskTitle, subtasks: []));
    notifyListeners();
  }

  // Add a subtask to a specific task
  void addSubtask(int taskIndex, String subtaskTitle) {
    tasks[taskIndex].subtasks.add(Subtask(title: subtaskTitle));
    notifyListeners();
  }

  // Remove a task
  void removeTask(int taskIndex) {
    tasks.removeAt(taskIndex);
    notifyListeners();
  }

  // Toggle task completion status
  void toggleTaskCompletion(int taskIndex) {
    tasks[taskIndex].isCompleted = !tasks[taskIndex].isCompleted;
    notifyListeners();
  }

  void toggleSubtaskCompletion(int taskIndex, int subtaskIndex) {
    tasks[taskIndex].subtasks[subtaskIndex].isCompleted =
        !tasks[taskIndex].subtasks[subtaskIndex].isCompleted;
    notifyListeners();
  }

  // Pomodoro timer start/pause/stop
  void startTimer(bool isWorkSession) {
    remainingTime = (isWorkSession ? workDuration : breakDuration) * 60;
    isTimerRunning = true;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        remainingTime--;
        notifyListeners();
      } else {
        stopTimer();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    isTimerRunning = false;
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    isTimerRunning = false;
    remainingTime = 0;
    notifyListeners();
  }

  // Set custom durations
  void setDurations(int workMinutes, int breakMinutes) {
    workDuration = workMinutes;
    breakDuration = breakMinutes;
    notifyListeners();
  }
}
