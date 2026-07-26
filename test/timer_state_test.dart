import 'package:adhd_list/providers/timer_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

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

    test('completes a session by switching to the next ready mode', () {
      fakeAsync((_) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final state = TimerState(now: () => now);
        state.updateDurations(focus: 1, shortBreak: 5, longBreak: 15);

        state.startTimer();
        now = now.add(const Duration(minutes: 1));
        state.syncWithClock();

        expect(state.isTimerRunning, isFalse);
        expect(state.currentMode, 'Short Break');
        expect(state.timerDisplay, '05:00');
        expect(state.statusLabel, 'Short Break ready');
        expect(state.completionMessage, 'Focus complete. Short Break ready.');
        state.dispose();
      });
    });

    test('syncs stale running sessions against the clock', () {
      fakeAsync((_) {
        final startedAt = DateTime(2026, 6, 23, 9);
        var now = startedAt;
        final state = TimerState(now: () => now);
        state.updateDurations(focus: 1, shortBreak: 5, longBreak: 15);

        state.startTimer();
        now = startedAt.add(const Duration(seconds: 30));
        state.syncWithClock();

        expect(state.isTimerRunning, isTrue);
        expect(state.timerDisplay, '00:30');

        now = startedAt.add(const Duration(seconds: 75));
        state.syncWithClock();

        expect(state.isTimerRunning, isFalse);
        expect(state.currentMode, 'Short Break');
        expect(state.timerDisplay, '05:00');
        expect(state.completionMessage, 'Focus complete. Short Break ready.');
        state.dispose();
      });
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
