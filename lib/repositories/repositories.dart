abstract interface class TaskRepository {
  Future<int> insertTask(String title, String dueDate);
  Future<List<Map<String, dynamic>>> fetchTasks();
  Future<void> editTask(int id, String title, String dueDate);
  Future<void> updateTaskStatus(int taskId, String status);
  Future<void> deleteTask(int id);
  Future<void> clearTasks();
  Future<int> insertSubtask(int taskId, String title);
  Future<List<Map<String, dynamic>>> fetchSubtasks(int taskId);
  Future<void> updateSubtask(int subtaskId, String title);
  Future<void> updateSubtaskStatus(int subtaskId, bool isCompleted);
  Future<void> deleteSubtask(int subtaskId);
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
