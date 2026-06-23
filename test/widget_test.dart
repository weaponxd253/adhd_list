import 'package:adhd_list/providers/timer_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimerState', () {
    test('starts with a full focus session', () {
      final state = TimerState();

      expect(state.currentMode, 'Focus');
      expect(state.timerDisplay, '25:00');
      expect(state.progress, 1);

      state.dispose();
    });

    test('switching modes resets the matching duration', () {
      final state = TimerState();

      state.setMode('Short Break');
      expect(state.currentMode, 'Short Break');
      expect(state.timerDisplay, '05:00');

      state.switchToNextMode();
      expect(state.currentMode, 'Long Break');
      expect(state.timerDisplay, '15:00');

      state.dispose();
    });
  });
}
