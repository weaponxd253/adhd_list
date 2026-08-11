import 'package:adhd_list/providers/timer_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('TimerState', () {
    test('starts with a full focus session', () {
      final state = TimerState();
      addTearDown(state.dispose);

      expect(state.currentMode, 'Focus');
      expect(state.timerDisplay, '25:00');
      expect(state.progress, 1);
      expect(state.isTimerRunning, isFalse);
    });

    test('start, pause, resume, and reset are deterministic', () {
      fakeAsync((_) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final state = TimerState(now: () => now);
        state.focusDuration = 1;
        state.resetTimer();

        state.startTimer();
        now = now.add(const Duration(seconds: 3));
        state.syncWithClock();
        expect(state.timerDisplay, '00:57');

        state.pauseTimer();
        now = now.add(const Duration(seconds: 5));
        state.syncWithClock();
        expect(state.timerDisplay, '00:57');

        state.startTimer();
        now = now.add(const Duration(seconds: 2));
        state.syncWithClock();
        expect(state.timerDisplay, '00:55');

        state.resetTimer();
        expect(state.timerDisplay, '01:00');
        expect(state.isTimerRunning, isFalse);
        state.dispose();
      });
    });

    test('switching modes stops and resets the timer', () {
      fakeAsync((async) {
        final state = TimerState();
        state.startTimer();
        async.elapse(const Duration(seconds: 2));

        state.switchToNextMode();
        expect(state.currentMode, 'Short Break');
        expect(state.timerDisplay, '05:00');
        expect(state.isTimerRunning, isFalse);

        state.switchToNextMode();
        expect(state.currentMode, 'Long Break');
        expect(state.timerDisplay, '15:00');
        state.dispose();
      });
    });

    test('updates durations and resets idle sessions', () {
      final state = TimerState();
      addTearDown(state.dispose);

      state.updateDurations(focus: 50, shortBreak: 10, longBreak: 30);

      expect(state.focusDuration, 50);
      expect(state.shortBreakDuration, 10);
      expect(state.longBreakDuration, 30);
      expect(state.timerDisplay, '50:00');

      state.switchToNextMode();
      expect(state.timerDisplay, '10:00');
    });

    test('quick focus starts a short focus session without changing settings',
        () {
      final state = TimerState();
      addTearDown(state.dispose);

      final started = state.startQuickFocus(5);

      expect(started, isTrue);
      expect(state.currentMode, 'Focus');
      expect(state.timerDisplay, '05:00');
      expect(state.isTimerRunning, isTrue);
      expect(state.focusDuration, 25);
    });

    test('quick focus does not replace a running timer', () {
      fakeAsync((_) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final state = TimerState(now: () => now);
        state.startTimer();
        now = now.add(const Duration(minutes: 3));
        state.syncWithClock();

        final started = state.startQuickFocus(2);

        expect(started, isFalse);
        expect(state.currentMode, 'Focus');
        expect(state.timerDisplay, '22:00');
        expect(state.isTimerRunning, isTrue);
        state.dispose();
      });
    });

    test('completes a session by switching to the next ready mode', () {
      fakeAsync((async) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final repository = FakeTimerSessionRepository();
        final state = TimerState(
          now: () => now,
          sessionRepository: repository,
        );
        state.updateDurations(focus: 1, shortBreak: 5, longBreak: 15);

        state.startTimer();
        now = now.add(const Duration(minutes: 1));
        state.syncWithClock();
        async.flushMicrotasks();

        expect(state.isTimerRunning, isFalse);
        expect(state.currentMode, 'Short Break');
        expect(state.timerDisplay, '05:00');
        expect(state.statusLabel, 'Short Break ready');
        expect(state.completionMessage, 'Focus complete. Short Break ready.');
        expect(repository.sessionRows, hasLength(1));
        expect(repository.sessionRows.single['mode'], 'Focus');
        expect(repository.sessionRows.single['duration_seconds'], 60);
        state.dispose();
      });
    });

    test('syncs stale running sessions against the clock', () {
      fakeAsync((async) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final repository = FakeTimerSessionRepository();
        final state = TimerState(
          now: () => now,
          sessionRepository: repository,
        );
        state.updateDurations(focus: 1, shortBreak: 5, longBreak: 15);

        state.startTimer();
        now = startedAt.add(const Duration(seconds: 30));
        state.syncWithClock();

        expect(state.isTimerRunning, isTrue);
        expect(state.timerDisplay, '00:30');

        now = startedAt.add(const Duration(seconds: 75));
        state.syncWithClock();
        async.flushMicrotasks();

        expect(state.isTimerRunning, isFalse);
        expect(state.currentMode, 'Short Break');
        expect(state.timerDisplay, '05:00');
        expect(state.completionMessage, 'Focus complete. Short Break ready.');
        expect(repository.sessionRows, hasLength(1));
        state.dispose();
      });
    });

    test('loads history and computes today session stats', () async {
      final now = DateTime(2026, 6, 23, 12);
      final repository = FakeTimerSessionRepository(
        sessions: [
          {
            'id': 1,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 9).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 9, 25).toIso8601String(),
            'duration_seconds': 1500,
            'completed': 1,
          },
          {
            'id': 2,
            'mode': 'Short Break',
            'started_at': DateTime(2026, 6, 23, 9, 25).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 9, 30).toIso8601String(),
            'duration_seconds': 300,
            'completed': 1,
          },
          {
            'id': 3,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 22, 9).toIso8601String(),
            'ended_at': DateTime(2026, 6, 22, 9, 25).toIso8601String(),
            'duration_seconds': 1500,
            'completed': 1,
          },
        ],
      );
      final state = TimerState(
        now: () => now,
        sessionRepository: repository,
      );
      addTearDown(state.dispose);

      await state.loadSessionHistory();

      expect(state.sessionHistory, hasLength(3));
      expect(state.completedSessionsToday, 2);
      expect(state.focusMinutesToday, 25);
    });

    test('notification preference schedules and cancels timer completion', () {
      fakeAsync((async) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final notifications = FakeTimerNotificationService();
        final state = TimerState(
          now: () => now,
          notificationService: notifications,
          sessionRepository: FakeTimerSessionRepository(),
        );

        state.updateSettings(
          focus: 25,
          shortBreak: 5,
          longBreak: 15,
          notificationsEnabled: true,
        );
        state.startTimer();
        async.flushMicrotasks();

        expect(notifications.permissionRequests, 1);
        expect(notifications.scheduled, hasLength(1));
        expect(notifications.scheduled.single['title'], 'Focus complete');

        state.pauseTimer();
        async.flushMicrotasks();
        expect(notifications.cancelCount, 1);

        state.startTimer();
        async.flushMicrotasks();
        state.resetTimer();
        async.flushMicrotasks();

        expect(notifications.cancelCount, 2);
        state.dispose();
      });
    });

    test('notification permission can be requested before the timer starts',
        () async {
      final notifications = FakeTimerNotificationService();
      final state = TimerState(
        notificationService: notifications,
        sessionRepository: FakeTimerSessionRepository(),
      );
      addTearDown(state.dispose);

      state.updateSettings(
        focus: 25,
        shortBreak: 5,
        longBreak: 15,
        notificationsEnabled: true,
      );

      notifications.permissionGranted = false;
      expect(await state.requestNotificationPermission(), isFalse);
      expect(notifications.permissionRequests, 1);
      expect(state.notificationPermissionNeeded, isTrue);

      notifications.permissionGranted = true;
      expect(await state.requestNotificationPermission(), isTrue);
      expect(notifications.permissionRequests, 2);
      expect(state.notificationPermissionGranted, isTrue);
      expect(state.notificationPermissionNeeded, isFalse);
    });

    test('dispose cancels future ticks', () {
      fakeAsync((async) {
        final state = TimerState();
        var notifications = 0;
        state.addListener(() => notifications++);
        state.startTimer();
        final beforeDispose = notifications;

        state.dispose();
        async.elapse(const Duration(seconds: 5));

        expect(notifications, beforeDispose);
      });
    });
  });
}
