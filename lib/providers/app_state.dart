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
    loadMoodHistory();
  }

  // ----------------------------------------
  // Fields
  // ----------------------------------------

  // Theme
  ThemeMode _themeMode = ThemeMode.light;

  // Task Management
  List<Task> tasks = [];
  final TaskDatabase _taskDb = TaskDatabase();

  // Pomodoro Timer
  bool isTimerRunning = false;
  String currentMode = "Focus";
  int remainingTime = 1500;
  int focusDuration = 25;
  int shortBreakDuration = 5;
  int longBreakDuration = 15;
  int _currentDuration = 0;
  Timer? _timer;

  // Mood Tracking
  String _selectedMood = '';
  String _selectedMoodEmoji = '';
  List<Map<String, dynamic>> _moodHistory = [];

  List<Map<String, dynamic>> get moodHistoryList => _moodHistory;

  final Map<String, String> moodMessages = {
    "Hopeful":
        "It's wonderful to feel hope! Nurture it by thinking of one small step you can take toward your goal today.",
    "Triggered":
        "Take a deep breath. It's okay to feel this way. Ground yourself by focusing on something you can see, touch, hear, or smell.",
    "Calm":
        "Feeling calm is a gift. Take a moment to enjoy this peace and consider what helps you stay centered.",
    "Mindful":
        "Notice the details around you. How does your body feel? Mindfulness can be powerful for well-being.",
    "Empowered":
        "You've got this! Use this energy to take a step forward. What will you accomplish today?",
    "Vulnerable":
        "Being vulnerable takes courage. Remember, it's okay to lean on others for support when you need it.",
    "Validated":
        "Feeling seen and understood can be incredibly comforting. Take a moment to appreciate this.",
    "Grounded":
        "Feel the earth beneath you. Centering yourself brings peace. Reflect on something steady in your life.",
    "Disconnected":
        "Feeling disconnected can be tough. Try reaching out to someone or doing an activity that brings you joy.",
    "Optimistic":
        "Optimism lights the way forward! Keep this positive outlook and share it with others when you can.",
    "Distracted":
        "It's okay to feel scattered. Try a quick reset: close your eyes, breathe deeply, and focus on one small task.",
    "Grieving":
        "Grief takes time. Allow yourself to feel it without judgment. Reach out to loved ones or take a gentle step toward healing.",
    "Rejected":
        "Rejection hurts, but remember: it doesn't define you. You are worthy and valued just as you are.",
    "Accepted":
        "Acceptance is a beautiful thing. Celebrate who you are and the journey that brought you here.",
    "Lonely":
        "Loneliness is a shared human experience. Try connecting with someone or doing an activity that brings you joy.",
    "Burnt Out":
        "Burnout is a sign to slow down. Prioritize rest and ask for help where you can. Your well-being matters.",
    "Resilient":
        "You've come through so much. Honor your resilience and think about what's helped you stay strong.",
    "Centered":
        "Being centered helps us weather life's storms. Carry this feeling with you as a reminder of your strength.",
    "Panicked":
        "Panic can feel overwhelming. Try to breathe deeply and ground yourself by counting backward from ten.",
    "Encouraged":
        "Encouragement fuels us forward! Keep this spirit close and consider sharing it with someone who needs it.",
    "Inspired":
        "Feeling inspired is powerful. Write down your ideas, and take even a small step toward bringing them to life.",
    "Exhausted":
        "You deserve rest. Allow yourself time to recharge. Listen to your body and take care of yourself.",
    "Content":
        "Contentment brings balance. Take a deep breath and appreciate the small things that bring you joy.",
    "Irritable":
        "Irritability is natural. Take a step back and identify what's bothering you. Gentle self-care can help.",
    "Supported":
        "You're not alone. Lean into this support, and remember to appreciate those who uplift you.",
    "Relaxed":
        "Take this moment to enjoy the calm. Let yourself unwind and recharge for what's ahead.",
    "Joyful":
        "Happiness is contagious! Share your joy with others and savor this positive energy.",
    "Sad":
        "It's okay to feel sad. Give yourself time to process your emotions and know this too shall pass.",
    "Frustrated":
        "Frustration can be a sign of growth. Step back, take a deep breath, and approach the situation with fresh eyes.",
    "Anxious":
        "Anxiety is tough, but you're stronger. Try grounding yourself with slow breaths and focusing on the present.",
    "Thoughtful":
        "Use this time to reflect and plan. What insights can you draw from your thoughts?",
    "Excited":
        "Let your excitement propel you forward! Channel this energy into something you're passionate about.",
    "Angry":
        "Anger can be powerful if directed positively. Pause, breathe, and think about how you can act constructively.",
    "Worried":
        "Worry is natural. Focus on what you can control and remind yourself that you're capable of overcoming challenges.",
    "Connected":
        "Connection is a gift. Cherish the moments you share with those around you.",
    "Numb":
        "Feeling numb can be hard. Take small steps to reconnect with your emotions and surroundings.",
    "Sleepy":
        "Listen to your body. Rest is essential, and a short nap or relaxation can work wonders.",
    "Relieved":
        "Relief brings peace. Appreciate the resolution and use this moment to celebrate your progress.",
    "Creative":
        "Creativity flows through you! Capture your ideas and bring them to life one step at a time.",
    "Peaceful":
        "Peace brings clarity. Take a moment to bask in this state and appreciate the serenity around you.",
    "Strong":
        "You've got this! Strength is not just physical but mental and emotional too. Keep pushing forward.",
    "Celebratory":
        "Celebrate your wins, big or small. Every step forward deserves recognition and joy.",
    "Confused":
        "Confusion is part of learning. Take your time to process, and clarity will follow.",
    "Indifferent":
        "Indifference can be a chance to reassess. What truly matters to you in this moment?",
    "Heartbroken":
        "Heartbreak is hard. Give yourself grace and time to heal, and remember you're not alone.",
    "Overwhelmed":
        "Overwhelm means you're handling a lot. Break it down into smaller tasks, and take it one step at a time.",
    "Tense":
        "Tension is a sign to pause. Stretch, breathe deeply, and let your body and mind relax.",
    "Intuitive":
        "Trust your instincts. Your intuition is guiding you toward what feels right.",
    "Grateful":
        "Gratitude brings perspective. Reflect on the things you're thankful for, no matter how small.",
  };

  // ----------------------------------------
  // Theme
  // ----------------------------------------

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // ----------------------------------------
  // Task Management
  // ----------------------------------------

  void addTask(String title, DateTime dueDate) async {
    await _taskDb.insertTask(title, dueDate.toIso8601String());
    _loadTasksFromDatabase();
  }

  void clearTaskHistory() async {
    await _taskDb.clearTasks();
    tasks.clear();
    notifyListeners();
  }

  void editTask(int taskId, String newTitle, DateTime newDueDate) async {
    await _taskDb.editTask(taskId, newTitle, newDueDate.toIso8601String());
    _loadTasksFromDatabase();
  }

  void deleteTask(int taskId) async {
    await _taskDb.deleteTask(taskId);
    _loadTasksFromDatabase();
  }

  void editSubtask(int taskIndex, int subtaskIndex, String newTitle) async {
    if (taskIndex >= 0 && taskIndex < tasks.length) {
      final task = tasks[taskIndex];
      if (subtaskIndex >= 0 && subtaskIndex < task.subtasks.length) {
        final subtask = task.subtasks[subtaskIndex];
        await _taskDb.updateSubtask(subtask.id, newTitle);
        subtask.title = newTitle;
        notifyListeners();
      }
    }
  }

  void deleteSubtask(int taskIndex, int subtaskIndex) async {
    if (taskIndex >= 0 && taskIndex < tasks.length) {
      final task = tasks[taskIndex];
      if (subtaskIndex >= 0 && subtaskIndex < task.subtasks.length) {
        final subtask = task.subtasks[subtaskIndex];
        await _taskDb.deleteSubtask(subtask.id);
        task.subtasks.removeAt(subtaskIndex);
        notifyListeners();
      }
    }
  }

  void _loadTasksFromDatabase() async {
    final fetchedTasks = await _taskDb.fetchTasks();
    tasks = [];
    for (final t in fetchedTasks) {
      final subtaskData = await _taskDb.fetchSubtasks(t['id']);
      final subtasks = subtaskData.map((s) => Subtask.fromMap(s)).toList();
      tasks.add(Task(
        id: t['id'],
        title: t['title'],
        dueDate: DateTime.parse(t['due_date']),
        // is_completed is always in sync with status (fixed in TaskDatabase)
        status: t['is_completed'] == 1 ? 'completed' : 'pending',
        completedAt: t['completed_at'] != null
            ? DateTime.tryParse(t['completed_at'] as String)
            : null,
        subtasks: subtasks,
      ));
    }
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
      final task = tasks[taskIndex];
      final newStatus = task.isCompleted ? 'pending' : 'completed';
      await _taskDb.updateTaskStatus(task.id, newStatus);
      task.status = newStatus;
      // Mirror completed_at in memory so currentStreak is accurate immediately
      // without waiting for a full DB reload.
      task.completedAt = newStatus == 'completed' ? DateTime.now() : null;
      notifyListeners();
    }
  }

  void updateTaskStatus(int taskId, String newStatus) async {
    await _taskDb.updateTaskStatus(taskId, newStatus);
    _loadTasksFromDatabase();
  }

  void addSubtask(int taskIndex, String subtaskTitle) async {
    if (taskIndex >= 0 && taskIndex < tasks.length) {
      final task = tasks[taskIndex];
      final subtaskId = await _taskDb.insertSubtask(task.id, subtaskTitle);
      task.subtasks.add(Subtask(id: subtaskId, title: subtaskTitle));
      notifyListeners();
    }
  }

  // Fixed: now persists to DB so the state survives app restarts.
  void toggleSubtaskCompletion(int taskIndex, int subtaskIndex) async {
    if (taskIndex >= 0 && taskIndex < tasks.length) {
      final task = tasks[taskIndex];
      if (subtaskIndex >= 0 && subtaskIndex < task.subtasks.length) {
        final subtask = task.subtasks[subtaskIndex];
        final newValue = !subtask.isCompleted;
        subtask.isCompleted = newValue;
        await _taskDb.updateSubtaskStatus(subtask.id, newValue);
        notifyListeners();
      }
    }
  }

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.isCompleted).length;
  int get pendingTasks => tasks.where((t) => !t.isCompleted).length;
  List<Task> get upcomingTasks =>
      tasks.where((t) => !t.isCompleted).take(3).toList();
  List<Task> get completedTaskList =>
      tasks.where((t) => t.isCompleted).toList();

  // Total subtasks completed across all tasks — used by TrackerScreen for points.
  int get completedSubtasks => tasks.fold(
        0,
        (sum, t) => sum + t.subtasks.where((s) => s.isCompleted).length,
      );

  // Points: 10 per completed task, 5 per completed subtask.
  int get totalPoints => (completedTasks * 10) + (completedSubtasks * 5);

  // Consecutive-day streak based on completed_at timestamps.
  // A day counts if at least one task was completed on it.
  // The streak is alive if a task was completed today or yesterday;
  // if the most recent completion was 2+ days ago, the streak is 0.
  int get currentStreak {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Collect the unique calendar dates on which tasks were completed.
    final completionDays = tasks
        .where((t) => t.isCompleted && t.completedAt != null)
        .map((t) {
          final d = t.completedAt!;
          return DateTime(d.year, d.month, d.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // most-recent first

    if (completionDays.isEmpty) return 0;

    // Streak is broken if the last active day was more than 1 day ago.
    final daysSinceLast = today.difference(completionDays.first).inDays;
    if (daysSinceLast > 1) return 0;

    int streak = 1;
    for (int i = 1; i < completionDays.length; i++) {
      final gap = completionDays[i - 1].difference(completionDays[i]).inDays;
      if (gap == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ----------------------------------------
  // Pomodoro Timer
  // ----------------------------------------

  void updateTimerDuration(String mode) {
    switch (mode) {
      case 'Focus':
        _currentDuration = focusDuration * 60;
        break;
      case 'Short Break':
        _currentDuration = shortBreakDuration * 60;
        break;
      case 'Long Break':
        _currentDuration = longBreakDuration * 60;
        break;
      default:
        _currentDuration = focusDuration * 60;
    }
    remainingTime = _currentDuration;
    notifyListeners();
  }

  void startTimer([bool? isFocus]) {
    if (isTimerRunning) return;
    isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    if (currentMode == 'Focus') {
      currentMode = 'Short Break';
    } else if (currentMode == 'Short Break') {
      currentMode = 'Long Break';
    } else {
      currentMode = 'Focus';
    }
    updateTimerDuration(currentMode);
    notifyListeners();
  }

  String get timerDisplay {
    final minutes = (remainingTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingTime % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress =>
      _currentDuration == 0 ? 0 : remainingTime / _currentDuration;

  void setMode(String mode) {
    currentMode = mode;
    notifyListeners();
  }

  int getCurrentDuration() {
    switch (currentMode) {
      case 'Focus':
        return focusDuration;
      case 'Short Break':
        return shortBreakDuration;
      case 'Long Break':
        return longBreakDuration;
      default:
        return focusDuration;
    }
  }

  // ----------------------------------------
  // Mood Tracking
  // ----------------------------------------

  String get selectedMood => _selectedMood;
  String get selectedMoodEmoji => _selectedMoodEmoji;
  String get moodMessage => moodMessages[_selectedMood] ?? 'No mood selected.';

  /// Saves a mood entry and refreshes the in-memory history.
  /// Single insert — no delete-all/re-insert race condition.
  void setMood(String mood, String emoji) async {
    _selectedMood = mood;
    _selectedMoodEmoji = emoji;
    notifyListeners();
    await MoodDatabase.instance.insertMood(mood, emoji);
    await loadMoodHistory();
  }

  Future<void> loadLastMood() async {
    final lastMood = await MoodDatabase.instance.fetchLastMood();
    if (lastMood != null) {
      _selectedMood = lastMood['mood'] as String;
      _selectedMoodEmoji = lastMood['emoji'] as String;
    } else {
      _selectedMood = '';
      _selectedMoodEmoji = '';
    }
    notifyListeners();
  }

  Future<void> loadMoodHistory() async {
    _moodHistory = await MoodDatabase.instance.fetchMoods();
    notifyListeners();
  }

  void clearMoodHistory() async {
    await MoodDatabase.instance.clearMoods();
    _moodHistory = [];
    _selectedMood = '';
    _selectedMoodEmoji = '';
    notifyListeners();
  }
}