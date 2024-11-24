// lib/providers/app_state.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/task.dart';
import '../models/subtask.dart';

class AppState extends ChangeNotifier {
  // ----------------------------------------
  // Fields
  // ----------------------------------------

  // Task Management
  List<Task> tasks = [];

  // Pomodoro Timer
  bool isTimerRunning = false;
  String currentMode = "Focus";
  int remainingTime = 0; // Remaining time in seconds
  int focusDuration = 25; // in minutes
  int shortBreakDuration = 5; // in minutes
  int longBreakDuration = 15; // in minutes
  int _currentDuration = 0; 
  Timer? _timer;

  // Mood Tracking
  String _selectedMood = '';
  String _selectedMoodEmoji = '';
  List<Map<String, String>> moodHistory = [];
final Map<String, String> moodMessages = {
  "Hopeful": "It’s wonderful to feel hope! Nurture it by thinking of one small step you can take toward your goal today.",
  "Triggered": "Take a deep breath. It's okay to feel this way. Ground yourself by focusing on something you can see, touch, hear, or smell.",
  "Calm": "Feeling calm is a gift. Take a moment to enjoy this peace and consider what helps you stay centered.",
  "Mindful": "Notice the details around you. How does your body feel? Mindfulness can be powerful for well-being.",
  "Empowered": "You’ve got this! Use this energy to take a step forward. What will you accomplish today?",
  "Vulnerable": "Being vulnerable takes courage. Remember, it’s okay to lean on others for support when you need it.",
  "Validated": "Feeling seen and understood can be incredibly comforting. Take a moment to appreciate this.",
  "Grounded": "Feel the earth beneath you. Centering yourself brings peace. Reflect on something steady in your life.",
  "Disconnected": "Feeling disconnected can be tough. Try reaching out to someone or doing an activity that brings you joy.",
  "Optimistic": "Optimism lights the way forward! Keep this positive outlook and share it with others when you can.",
  "Distracted": "It’s okay to feel scattered. Try a quick reset: close your eyes, breathe deeply, and focus on one small task.",
  "Grieving": "Grief takes time. Allow yourself to feel it without judgment. Reach out to loved ones or take a gentle step toward healing.",
  "Rejected": "Rejection hurts, but remember: it doesn’t define you. You are worthy and valued just as you are.",
  "Accepted": "Acceptance is a beautiful thing. Celebrate who you are and the journey that brought you here.",
  "Lonely": "Loneliness is a shared human experience. Try connecting with someone or doing an activity that brings you joy.",
  "Burnt Out": "Burnout is a sign to slow down. Prioritize rest and ask for help where you can. Your well-being matters.",
  "Resilient": "You’ve come through so much. Honor your resilience and think about what’s helped you stay strong.",
  "Centered": "Being centered helps us weather life’s storms. Carry this feeling with you as a reminder of your strength.",
  "Panicked": "Panic can feel overwhelming. Try to breathe deeply and ground yourself by counting backward from ten.",
  "Encouraged": "Encouragement fuels us forward! Keep this spirit close and consider sharing it with someone who needs it.",
  "Inspired": "Feeling inspired is powerful. Write down your ideas, and take even a small step toward bringing them to life.",
  "Exhausted": "You deserve rest. Allow yourself time to recharge. Listen to your body and take care of yourself.",
  "Content": "Contentment brings balance. Take a deep breath and appreciate the small things that bring you joy.",
  "Irritable": "Irritability is natural. Take a step back and identify what’s bothering you. Gentle self-care can help.",
  "Supported": "You’re not alone. Lean into this support, and remember to appreciate those who uplift you.",
};

  // ----------------------------------------
  // Task Management Methods
  // ----------------------------------------

  void addTask(String title, DateTime dueDate) {
    tasks.add(Task(title: title, dueDate: dueDate));
    notifyListeners();
  }

  void removeTask(int taskIndex) {
    if (taskIndex >= 0 && taskIndex < tasks.length) {
      tasks.removeAt(taskIndex);
      notifyListeners();
    }
  }

  void toggleTaskCompletion(int taskIndex) {
    if (taskIndex >= 0 && taskIndex < tasks.length) {
      tasks[taskIndex].isCompleted = !tasks[taskIndex].isCompleted;
      notifyListeners();
    }
  }

  void addSubtask(int taskIndex, String subtaskTitle) {
    if (taskIndex >= 0 && taskIndex < tasks.length) {
      tasks[taskIndex].subtasks.add(Subtask(title: subtaskTitle));
      notifyListeners();
    }
  }

  void toggleSubtaskCompletion(int taskIndex, int subtaskIndex) {
    if (taskIndex >= 0 && taskIndex < tasks.length) {
      Task task = tasks[taskIndex];
      if (subtaskIndex >= 0 && subtaskIndex < task.subtasks.length) {
        task.subtasks[subtaskIndex].isCompleted = !task.subtasks[subtaskIndex].isCompleted;
        notifyListeners();
      }
    }
  }

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => tasks.where((task) => !task.isCompleted).length;
  List<Task> get upcomingTasks => tasks.where((task) => !task.isCompleted).take(3).toList();

  // ----------------------------------------
  // Pomodoro Timer Methods
  // ----------------------------------------

  void updateTimerDuration(String mode) {
    switch (mode) {
      case "Focus":
        _currentDuration = focusDuration * 60;
        break;
      case "Short Break":
        _currentDuration = shortBreakDuration * 60;
        break;
      case "Long Break":
        _currentDuration = longBreakDuration * 60;
        break;
      default:
        _currentDuration = focusDuration * 60;
    }
    remainingTime = _currentDuration;
    notifyListeners();
  }

  void startTimer([bool? bool]) {
    if (isTimerRunning) return;

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

  void stopTimer() {
    _timer?.cancel();
    isTimerRunning = false;
    remainingTime = _currentDuration;
    notifyListeners();
  }

  void pauseTimer() {
    _timer?.cancel();
    isTimerRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    isTimerRunning = false;
    remainingTime = _currentDuration;
    notifyListeners();
  }

  String get timerDisplay {
    final minutes = (remainingTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingTime % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  double get progress =>
      _currentDuration == 0 ? 0 : remainingTime / _currentDuration;

  // ----------------------------------------
  // Mood Tracking Methods
  // ----------------------------------------

  String get selectedMood => _selectedMood;
  String get selectedMoodEmoji => _selectedMoodEmoji;

  void setMood(String mood, String emoji) {
  _selectedMood = mood;
  _selectedMoodEmoji = emoji;
  moodHistory.add({
    'mood': mood,
    'emoji': emoji,
    'date': DateTime.now().toLocal().toString().split(' ')[0],
  });
  notifyListeners(); // Notify UI of state changes
}


String get moodMessage => moodMessages[_selectedMood] ?? 'No mood selected.';

  // ----------------------------------------
  // Utility Methods
  // ----------------------------------------

  void setMode(String mode) {
    currentMode = mode;
    notifyListeners();
  }

  int getCurrentDuration() {
    switch (currentMode) {
      case "Focus":
        return focusDuration;
      case "Short Break":
        return shortBreakDuration;
      case "Long Break":
        return longBreakDuration;
      default:
        return focusDuration;
    }
  }
}
