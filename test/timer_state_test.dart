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
      expect(state.hasActiveTarget, isFalse);
      expect(state.activeTargetType, TimerState.targetTypeNone);
    });

    test('target focus starts with active task context', () {
      final state = TimerState();
      addTearDown(state.dispose);

      final started = state.startTargetFocus(
        minutes: 10,
        targetType: TimerState.targetTypeTask,
        taskId: 42,
        title: 'Write report',
      );

      expect(started, isTrue);
      expect(state.currentMode, 'Focus');
      expect(state.timerDisplay, '10:00');
      expect(state.isTimerRunning, isTrue);
      expect(state.hasActiveTarget, isTrue);
      expect(state.activeTargetType, TimerState.targetTypeTask);
      expect(state.activeTaskId, 42);
      expect(state.activeSubtaskId, isNull);
      expect(state.activeTargetTitle, 'Write report');
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

    test('reset and stop clear active target state', () {
      final state = TimerState();
      addTearDown(state.dispose);

      state.startTargetFocus(
        minutes: 10,
        targetType: TimerState.targetTypeSubtask,
        taskId: 42,
        subtaskId: 77,
        title: 'Find one source',
      );
      state.resetTimer();

      expect(state.hasActiveTarget, isFalse);
      expect(state.activeTaskId, isNull);
      expect(state.activeSubtaskId, isNull);
      expect(state.activeTargetTitle, isNull);

      state.startTargetFocus(
        minutes: 5,
        targetType: TimerState.targetTypeTask,
        taskId: 42,
        title: 'Write report',
      );
      state.stopTimer();

      expect(state.hasActiveTarget, isFalse);
      expect(state.activeTaskId, isNull);
      expect(state.activeSubtaskId, isNull);
      expect(state.activeTargetTitle, isNull);
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
        expect(repository.sessionRows.single['target_type'], 'none');
        expect(repository.sessionRows.single['outcome'], 'time_done_only');
        state.dispose();
      });
    });

    test('completed target focus saves task context', () {
      fakeAsync((async) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final repository = FakeTimerSessionRepository();
        final state = TimerState(
          now: () => now,
          sessionRepository: repository,
        );

        state.startTargetFocus(
          minutes: 10,
          targetType: TimerState.targetTypeSubtask,
          taskId: 42,
          subtaskId: 77,
          title: 'Find one source',
        );
        now = now.add(const Duration(minutes: 10));
        state.syncWithClock();
        async.flushMicrotasks();

        expect(repository.sessionRows, hasLength(1));
        expect(repository.sessionRows.single['task_id'], 42);
        expect(repository.sessionRows.single['subtask_id'], 77);
        expect(repository.sessionRows.single['target_type'], 'subtask');
        expect(
          repository.sessionRows.single['target_title_snapshot'],
          'Find one source',
        );
        expect(repository.sessionRows.single['outcome'], 'time_done_only');
        expect(state.sessionHistory.single.taskId, 42);
        expect(state.sessionHistory.single.subtaskId, 77);
        expect(state.sessionHistory.single.targetType, 'subtask');
        expect(
          state.sessionHistory.single.targetTitleSnapshot,
          'Find one source',
        );
        expect(state.hasActiveTarget, isFalse);
        state.dispose();
      });
    });

    test('linked completion outcomes update recorded sessions', () {
      fakeAsync((async) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final repository = FakeTimerSessionRepository();
        final state = TimerState(
          now: () => now,
          sessionRepository: repository,
        );

        state.startTargetFocus(
          minutes: 10,
          targetType: TimerState.targetTypeTask,
          taskId: 42,
          title: 'Write report',
        );
        now = now.add(const Duration(minutes: 10));
        state.syncWithClock();
        async.flushMicrotasks();

        expect(state.pendingCompletionTarget?.sessionId, 1);

        state.resolveLinkedCompletion(TimerState.outcomeLeftOpen);
        async.flushMicrotasks();

        expect(state.pendingCompletionTarget, isNull);
        expect(repository.sessionRows.single['outcome'], 'left_open');
        expect(state.sessionHistory.single.outcome, 'left_open');
        state.dispose();
      });
    });

    test('continue linked focus keeps the same target', () {
      fakeAsync((async) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final repository = FakeTimerSessionRepository();
        final state = TimerState(
          now: () => now,
          sessionRepository: repository,
        );

        state.startTargetFocus(
          minutes: 10,
          targetType: TimerState.targetTypeSubtask,
          taskId: 42,
          subtaskId: 77,
          title: 'Find one source',
        );
        now = now.add(const Duration(minutes: 10));
        state.syncWithClock();
        async.flushMicrotasks();

        state.continueLinkedFocus();
        async.flushMicrotasks();

        expect(repository.sessionRows.single['outcome'], 'continued');
        expect(state.isTimerRunning, isTrue);
        expect(state.timerDisplay, '05:00');
        expect(state.activeTaskId, 42);
        expect(state.activeSubtaskId, 77);
        expect(state.activeTargetType, TimerState.targetTypeSubtask);
        expect(state.activeTargetTitle, 'Find one source');
        state.dispose();
      });
    });

    test('ending linked focus early records elapsed time', () {
      fakeAsync((async) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final repository = FakeTimerSessionRepository();
        final state = TimerState(
          now: () => now,
          sessionRepository: repository,
        );

        state.startTargetFocus(
          minutes: 10,
          targetType: TimerState.targetTypeTask,
          taskId: 42,
          title: 'Write report',
        );
        now = now.add(const Duration(seconds: 150));
        state.syncWithClock();

        final ended = state.endCurrentSessionEarly();
        async.flushMicrotasks();

        expect(ended, isTrue);
        expect(state.isTimerRunning, isFalse);
        expect(state.hasActiveSession, isFalse);
        expect(state.currentMode, 'Short Break');
        expect(state.completionMessage, 'Focus ended. Short Break ready.');
        expect(state.pendingCompletionTarget?.taskId, 42);
        expect(repository.sessionRows.single['duration_seconds'], 150);
        expect(repository.sessionRows.single['task_id'], 42);
        expect(repository.sessionRows.single['outcome'], 'time_done_only');
        state.dispose();
      });
    });

    test('paused linked focus cannot be replaced and can end early', () {
      fakeAsync((async) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final repository = FakeTimerSessionRepository();
        final state = TimerState(
          now: () => now,
          sessionRepository: repository,
        );

        state.startTargetFocus(
          minutes: 5,
          targetType: TimerState.targetTypeSubtask,
          taskId: 42,
          subtaskId: 77,
          title: 'Find one source',
        );
        now = now.add(const Duration(seconds: 60));
        state.syncWithClock();
        state.pauseTimer();

        final replaced = state.startTargetFocus(
          minutes: 2,
          targetType: TimerState.targetTypeTask,
          taskId: 99,
          title: 'Other task',
        );
        final ended = state.endCurrentSessionEarly();
        async.flushMicrotasks();

        expect(replaced, isFalse);
        expect(ended, isTrue);
        expect(repository.sessionRows.single['duration_seconds'], 60);
        expect(repository.sessionRows.single['task_id'], 42);
        expect(repository.sessionRows.single['subtask_id'], 77);
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
      expect(state.sessionHistory.last.targetType, TimerState.targetTypeNone);
      expect(state.sessionHistory.last.taskId, isNull);
      expect(state.completedSessionsToday, 2);
      expect(state.focusMinutesToday, 25);
    });

    test('computes focus minutes for linked tasks and subtasks', () async {
      final repository = FakeTimerSessionRepository(
        sessions: [
          {
            'id': 1,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 9).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 9, 10).toIso8601String(),
            'duration_seconds': 600,
            'completed': 1,
            'task_id': 42,
            'subtask_id': 77,
            'target_type': TimerState.targetTypeSubtask,
          },
          {
            'id': 2,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 10).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 10, 5).toIso8601String(),
            'duration_seconds': 300,
            'completed': 1,
            'task_id': 42,
            'target_type': TimerState.targetTypeTask,
          },
          {
            'id': 3,
            'mode': 'Short Break',
            'started_at': DateTime(2026, 6, 23, 10, 5).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 10, 10).toIso8601String(),
            'duration_seconds': 300,
            'completed': 1,
            'task_id': 42,
            'target_type': TimerState.targetTypeTask,
          },
        ],
      );
      final state = TimerState(sessionRepository: repository);
      addTearDown(state.dispose);

      await state.loadSessionHistory();

      expect(state.focusMinutesForTask(42), 15);
      expect(state.focusMinutesForSubtask(77), 10);
      expect(state.focusMinutesForTask(99), 0);
    });

    test('summarizes focus time by task and subtask', () async {
      final repository = FakeTimerSessionRepository(
        sessions: [
          {
            'id': 1,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 9).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 9, 2).toIso8601String(),
            'duration_seconds': 120,
            'completed': 1,
            'task_id': 42,
            'subtask_id': 7,
            'target_type': TimerState.targetTypeSubtask,
            'target_title_snapshot': 'Find source',
            'outcome': TimerState.outcomeLeftOpen,
          },
          {
            'id': 2,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 9, 10).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 9, 15).toIso8601String(),
            'duration_seconds': 300,
            'completed': 1,
            'task_id': 42,
            'subtask_id': 8,
            'target_type': TimerState.targetTypeSubtask,
            'target_title_snapshot': 'Write notes',
            'outcome': TimerState.outcomeSubtaskCompleted,
          },
          {
            'id': 3,
            'mode': 'Short Break',
            'started_at': DateTime(2026, 6, 23, 9, 15).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 9, 20).toIso8601String(),
            'duration_seconds': 300,
            'completed': 1,
            'task_id': 42,
            'target_type': TimerState.targetTypeTask,
          },
          {
            'id': 4,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 10).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 10, 10).toIso8601String(),
            'duration_seconds': 600,
            'completed': 1,
            'task_id': 99,
            'target_type': TimerState.targetTypeTask,
          },
        ],
      );
      final state = TimerState(sessionRepository: repository);
      addTearDown(state.dispose);

      await state.loadSessionHistory();

      final summary = state.focusSummaryForTask(42);
      expect(summary.focusMinutes, 7);
      expect(summary.sessionCount, 2);
      expect(summary.subtaskFocusMinutes(7), 2);
      expect(summary.subtaskFocusMinutes(8), 5);
    });

    test('finds the latest target that is still left open', () async {
      final repository = FakeTimerSessionRepository(
        sessions: [
          {
            'id': 1,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 9).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 9, 5).toIso8601String(),
            'duration_seconds': 300,
            'completed': 1,
            'task_id': 42,
            'target_type': TimerState.targetTypeTask,
            'target_title_snapshot': 'Essay',
            'outcome': TimerState.outcomeLeftOpen,
          },
          {
            'id': 2,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 9, 10).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 9, 15).toIso8601String(),
            'duration_seconds': 300,
            'completed': 1,
            'task_id': 42,
            'target_type': TimerState.targetTypeTask,
            'target_title_snapshot': 'Essay',
            'outcome': TimerState.outcomeContinued,
          },
          {
            'id': 3,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 10).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 10, 5).toIso8601String(),
            'duration_seconds': 300,
            'completed': 1,
            'task_id': 99,
            'target_type': TimerState.targetTypeTask,
            'target_title_snapshot': 'Lab',
            'outcome': TimerState.outcomeLeftOpen,
          },
        ],
      );
      final state = TimerState(sessionRepository: repository);
      addTearDown(state.dispose);

      await state.loadSessionHistory();

      expect(state.latestOpenFocusSessionForTaskIds([42]), isNull);
      expect(
        state.latestOpenFocusSessionForTaskIds([42, 99])?.targetTitleSnapshot,
        'Lab',
      );
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
