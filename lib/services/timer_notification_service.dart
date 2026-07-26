abstract interface class TimerNotificationService {
  Future<bool> requestPermission();

  Future<void> scheduleTimerCompletion({
    required DateTime when,
    required String title,
    required String body,
  });

  Future<void> cancelTimerCompletion();
}

class NoopTimerNotificationService implements TimerNotificationService {
  const NoopTimerNotificationService();

  @override
  Future<void> cancelTimerCompletion() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleTimerCompletion({
    required DateTime when,
    required String title,
    required String body,
  }) async {}
}
