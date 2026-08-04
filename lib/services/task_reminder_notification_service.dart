abstract interface class TaskReminderNotificationService {
  Future<bool> requestPermission();

  Future<void> scheduleTaskReminder({
    required int taskId,
    required DateTime when,
    required String title,
    required String body,
  });

  Future<void> cancelTaskReminder(int taskId);
  Future<void> cancelAllTaskReminders();
}

class NoopTaskReminderNotificationService
    implements TaskReminderNotificationService {
  const NoopTaskReminderNotificationService();

  @override
  Future<void> cancelAllTaskReminders() async {}

  @override
  Future<void> cancelTaskReminder(int taskId) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleTaskReminder({
    required int taskId,
    required DateTime when,
    required String title,
    required String body,
  }) async {}
}
