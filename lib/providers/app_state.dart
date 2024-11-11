// lib/providers/app_state.dart
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // Sample state variables
  List<String> tasks = [];
  bool isTimerRunning = false;

  // Method to add a new task
  void addTask(String task) {
    tasks.add(task);
    notifyListeners(); // Notify listeners of state change
  }

  // Method to remove a task
  void removeTask(String task) {
    tasks.remove(task);
    notifyListeners();
  }

  // Method to toggle timer state
  void toggleTimer() {
    isTimerRunning = !isTimerRunning;
    notifyListeners();
  }
}
