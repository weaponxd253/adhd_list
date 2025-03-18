// lib/providers/app_state.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../database/mood_database.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../database/task_database.dart';


class AppState extends ChangeNotifier {
    AppState() {
    loadLastMood();
    _loadTasksFromDatabase();
  }
  // ----------------------------------------
  // Fields
  // ----------------------------------------

  //Theme
   ThemeMode _themeMode = ThemeMode.light;
  // Task Management
  List<Task> tasks = [];

  final TaskDatabase _taskDb = TaskDatabase();
  
  // Pomodoro Timer
  bool isTimerRunning = false;
  String currentMode = "Focus";
  int remainingTime = 1500; // Remaining time in seconds
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
  "Relaxed": "Take this moment to enjoy the calm. Let yourself unwind and recharge for what's ahead.",
  "Joyful": "Happiness is contagious! Share your joy with others and savor this positive energy.",
  "Sad": "It's okay to feel sad. Give yourself time to process your emotions and know this too shall pass.",
  "Frustrated": "Frustration can be a sign of growth. Step back, take a deep breath, and approach the situation with fresh eyes.",
  "Anxious": "Anxiety is tough, but you're stronger. Try grounding yourself with slow breaths and focusing on the present.",
  "Thoughtful": "Use this time to reflect and plan. What insights can you draw from your thoughts?",
  "Excited": "Let your excitement propel you forward! Channel this energy into something you're passionate about.",
  "Angry": "Anger can be powerful if directed positively. Pause, breathe, and think about how you can act constructively.",
  "Worried": "Worry is natural. Focus on what you can control and remind yourself that you’re capable of overcoming challenges.",
  "Connected": "Connection is a gift. Cherish the moments you share with those around you.",
  "Numb": "Feeling numb can be hard. Take small steps to reconnect with your emotions and surroundings.",
  "Sleepy": "Listen to your body. Rest is essential, and a short nap or relaxation can work wonders.",
  "Relieved": "Relief brings peace. Appreciate the resolution and use this moment to celebrate your progress.",
  "Creative": "Creativity flows through you! Capture your ideas and bring them to life one step at a time.",
  "Peaceful": "Peace brings clarity. Take a moment to bask in this state and appreciate the serenity around you.",
  "Strong": "You’ve got this! Strength is not just physical but mental and emotional too. Keep pushing forward.",
  "Celebratory": "Celebrate your wins, big or small. Every step forward deserves recognition and joy.",
  "Confused": "Confusion is part of learning. Take your time to process, and clarity will follow.",
  "Indifferent": "Indifference can be a chance to reassess. What truly matters to you in this moment?",
  "Heartbroken": "Heartbreak is hard. Give yourself grace and time to heal, and remember you're not alone.",
  "Overwhelmed": "Overwhelm means you're handling a lot. Break it down into smaller tasks, and take it one step at a time.",
  "Tense": "Tension is a sign to pause. Stretch, breathe deeply, and let your body and mind relax.",
  "Intuitive": "Trust your instincts. Your intuition is guiding you toward what feels right.",
  "Grateful": "Gratitude brings perspective. Reflect on the things you’re thankful for, no matter how small.",
};

  // ----------------------------------------
  // Theme Changer
  // ----------------------------------------
   ThemeMode get themeMode => _themeMode;
   
   void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notify UI to rebuild
  }

  // ----------------------------------------
  // Task Management Methods
  // ----------------------------------------

void addTask(String title, DateTime dueDate) async {
  await _taskDb.insertTask(title, dueDate.toIso8601String()); // Save to DB
  _loadTasksFromDatabase(); // Reload from DB
}

void clearTaskHistory() async {
  await _taskDb.clearTasks(); // Ensure this method exists in TaskDatabase
  tasks.clear();
  notifyListeners();
}

void clearMoodHistory() async {
  await MoodDatabase.instance.clearMoods(); // Ensure this method exists in MoodDatabase
  moodHistory.clear();
  notifyListeners();
}



void _loadTasksFromDatabase() async {
  final fetchedTasks = await _taskDb.fetchTasks();
  tasks = fetchedTasks.map((t) => Task(
    id: t['id'],
    title: t['title'],
    dueDate: DateTime.parse(t['due_date']),
    status: t['is_completed'] == 1 ? "completed" : "pending", // ✅ Convert boolean to status
  )).toList();
  notifyListeners();
}


  void removeTask(int taskIndex) {
    if (taskIndex >= 0 && taskIndex < tasks.length) {
      tasks.removeAt(taskIndex);
      notifyListeners();
    }
  }

void toggleTaskCompletion(int taskIndex) async {
  if (taskIndex >= 0 && taskIndex < tasks.length) {
    Task task = tasks[taskIndex];
    
    // Toggle between "completed" and "pending"
    String newStatus = task.isCompleted ? "pending" : "completed";

    await _taskDb.updateTaskStatus(task.id, newStatus); // Update database

    task.status = newStatus; // Update local task object
    notifyListeners(); // Refresh UI
  }
}


void updateTaskStatus(int taskId, String newStatus) async {
  await _taskDb.updateTaskStatus(taskId, newStatus); //  Update in database
  _loadTasksFromDatabase(); // Refresh task list
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
      task.subtasks[subtaskIndex].isCompleted = !task.subtasks[subtaskIndex].isCompleted; // ✅ Toggle subtask completion
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
   updateTimerDuration(currentMode);
    notifyListeners();
  }

  void switchToNextMode() {
  if (currentMode == "Focus") {
    currentMode = "Short Break";
  } else if (currentMode == "Short Break") {
    currentMode = "Long Break";
  } else {
    currentMode = "Focus";
  }
  updateTimerDuration(currentMode); // Update the timer for the new mode
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

void setMood(String mood, String emoji) async {
  _selectedMood = mood;
  _selectedMoodEmoji = emoji;

  await MoodDatabase.instance.updateLastMood(mood, emoji);
  
  // Fetch the latest mood from the database to ensure it's current
  await loadLastMood();

  notifyListeners(); // Notify UI of state changes
}


Future<void> loadLastMood() async {
  final lastMood = await MoodDatabase.instance.fetchLastMood();

  if (lastMood != null) {
    _selectedMood = lastMood['mood'];
    _selectedMoodEmoji = lastMood['emoji'];
  } else {
    _selectedMood = '';
    _selectedMoodEmoji = '';
  }

  notifyListeners(); 
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
