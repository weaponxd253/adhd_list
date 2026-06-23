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
      fakeAsync((async) {
        final state = TimerState();
        state.focusDuration = 1;
        state.resetTimer();

        state.startTimer();
        async.elapse(const Duration(seconds: 3));
        expect(state.timerDisplay, '00:57');

        state.pauseTimer();
        async.elapse(const Duration(seconds: 5));
        expect(state.timerDisplay, '00:57');

        state.startTimer();
        async.elapse(const Duration(seconds: 2));
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
