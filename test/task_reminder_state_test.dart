import 'package:adhd_list/models/task.dart';
import 'package:adhd_list/models/task_reminder.dart';
import 'package:adhd_list/providers/task_reminder_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('TaskReminderState', () {
    final now = DateTime(2026, 6, 23, 14, 30);
    final task = Task(
      id: 7,
      title: 'Email teacher',
      dueDate: DateTime(2026, 6, 24),
    );

    test('loads persisted reminders', () async {
      final repository = FakeTaskReminderRepository(
        reminders: [
          {
            'task_id': 7,
            'style': 'direct',
            'scheduled_at': DateTime(2026, 6, 24, 9).toIso8601String(),
            'enabled': 1,
          },
        ],
      );
      final state = TaskReminderState(
        repository: repository,
        notificationService: FakeTaskReminderNotificationService(),
        autoLoad: false,
      );
      addTearDown(state.dispose);

      await state.loadReminders();

      expect(state.reminderFor(7)?.style, TaskReminderStyle.direct);
      expect(state.activeReminderCount, 1);
    });

    test('schedules tomorrow reminders with the selected style', () async {
      final repository = FakeTaskReminderRepository();
      final notificationService = FakeTaskReminderNotificationService();
      final state = TaskReminderState(
        repository: repository,
        notificationService: notificationService,
        now: () => now,
        autoLoad: false,
      );
      addTearDown(state.dispose);
      state.updateSettings(
        remindersEnabled: true,
        defaultStyle: TaskReminderStyle.tinyStep,
      );

      final scheduled = await state.remindTomorrow(
        task,
        tinyStep: 'Open the email draft',
      );

      expect(scheduled, isTrue);
      expect(notificationService.permissionRequests, 1);
      expect(notificationService.scheduled.single['taskId'], 7);
      expect(
          notificationService.scheduled.single['body'], 'Open the email draft');
      expect(
        notificationService.scheduled.single['when'],
        DateTime(2026, 6, 24, 9),
      );
      expect(repository.reminderRows.single['style'], 'tinyStep');
      expect(state.reminderFor(7)?.scheduledAt, DateTime(2026, 6, 24, 9));
    });

    test('does not schedule while task nudges are off', () async {
      final repository = FakeTaskReminderRepository();
      final notificationService = FakeTaskReminderNotificationService();
      final state = TaskReminderState(
        repository: repository,
        notificationService: notificationService,
        now: () => now,
        autoLoad: false,
      );
      addTearDown(state.dispose);

      final scheduled = await state.remindLater(
        task,
        tinyStep: 'Open the email draft',
      );

      expect(scheduled, isFalse);
      expect(notificationService.scheduled, isEmpty);
      expect(repository.reminderRows, isEmpty);
      expect(state.lastError, 'Task nudges are off.');
    });

    test('does not persist reminders when permission is denied', () async {
      final repository = FakeTaskReminderRepository();
      final notificationService = FakeTaskReminderNotificationService()
        ..permissionGranted = false;
      final state = TaskReminderState(
        repository: repository,
        notificationService: notificationService,
        now: () => now,
        autoLoad: false,
      );
      addTearDown(state.dispose);
      state.updateSettings(
        remindersEnabled: true,
        defaultStyle: TaskReminderStyle.gentle,
      );

      final scheduled = await state.remindLater(
        task,
        tinyStep: 'Open the email draft',
      );

      expect(scheduled, isFalse);
      expect(notificationService.scheduled, isEmpty);
      expect(repository.reminderRows, isEmpty);
      expect(state.notificationPermissionGranted, isFalse);
    });

    test('cancels stored and scheduled reminders', () async {
      final repository = FakeTaskReminderRepository();
      final notificationService = FakeTaskReminderNotificationService();
      final state = TaskReminderState(
        repository: repository,
        notificationService: notificationService,
        now: () => now,
        autoLoad: false,
      );
      addTearDown(state.dispose);
      state.updateSettings(
        remindersEnabled: true,
        defaultStyle: TaskReminderStyle.gentle,
      );
      await state.remindLater(task, tinyStep: 'Open the email draft');

      await state.cancelReminder(7);

      expect(notificationService.canceledTaskIds, contains(7));
      expect(repository.reminderRows, isEmpty);
      expect(state.reminderFor(7), isNull);
    });
  });
}
