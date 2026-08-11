abstract interface class TaskRepository {
  Future<int> insertTask(String title, String dueDate, {int? estimatedMinutes});
  Future<List<Map<String, dynamic>>> fetchTasks();
  Future<void> editTask(int id, String title, String dueDate);
  Future<void> updateTaskEstimate(int taskId, int? estimatedMinutes);
  Future<void> updateTaskStatus(int taskId, String status);
  Future<void> updateTaskSupport(
    int taskId, {
    String? friction,
    String? energyLevel,
    String? timeEstimate,
    String? anxietyLevel,
  });
  Future<void> deleteTask(int id);
  Future<void> clearTasks();
  Future<int> insertSubtask(
    int taskId,
    String title, {
    int? estimatedMinutes,
  });
  Future<List<Map<String, dynamic>>> fetchSubtasks(int taskId);
  Future<void> updateSubtask(
    int subtaskId,
    String title, {
    int? estimatedMinutes,
  });
  Future<void> updateSubtaskStatus(int subtaskId, bool isCompleted);
  Future<void> deleteSubtask(int subtaskId);
}

abstract interface class TaskReminderRepository {
  Future<List<Map<String, dynamic>>> fetchTaskReminders();
  Future<Map<String, dynamic>?> fetchTaskReminder(int taskId);
  Future<void> upsertTaskReminder({
    required int taskId,
    required String style,
    required String scheduledAt,
    bool enabled = true,
  });
  Future<void> deleteTaskReminder(int taskId);
  Future<void> clearTaskReminders();
}

abstract interface class MoodRepository {
  Future<Map<String, dynamic>?> fetchLastMood();
  Future<int> insertMood(String mood, String emoji);
  Future<List<Map<String, dynamic>>> fetchMoods();
  Future<void> clearMoods();
}

abstract interface class SettingsRepository {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

abstract interface class TimerSessionRepository {
  Future<int> insertSession(Map<String, Object?> session);
  Future<List<Map<String, Object?>>> fetchSessions({int limit = 60});
  Future<void> clearSessions();
}
