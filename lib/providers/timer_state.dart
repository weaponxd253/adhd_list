import 'dart:async';

import 'package:flutter/foundation.dart';

class TimerState extends ChangeNotifier {
  TimerState() {
    _resetDuration();
  }

  bool isTimerRunning = false;
  String currentMode = 'Focus';
  int remainingTime = 0;
  int focusDuration = 25;
  int shortBreakDuration = 5;
  int longBreakDuration = 15;

  int _currentDuration = 0;
  Timer? _timer;

  int _durationForMode(String mode) {
    switch (mode) {
      case 'Short Break':
        return shortBreakDuration * 60;
      case 'Long Break':
        return longBreakDuration * 60;
      default:
        return focusDuration * 60;
    }
  }

  void _resetDuration() {
    _currentDuration = _durationForMode(currentMode);
    remainingTime = _currentDuration;
  }

  void startTimer() {
    if (isTimerRunning) return;
    isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingTime > 0) {
        remainingTime--;
        notifyListeners();
      } else {
        stopTimer();
      }
    });
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    isTimerRunning = false;
    _resetDuration();
    notifyListeners();
  }

  void pauseTimer() {
    _timer?.cancel();
    isTimerRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    isTimerRunning = false;
    _resetDuration();
    notifyListeners();
  }

  void setMode(String mode) {
    if (!isTimerRunning &&
        mode == currentMode &&
        remainingTime == _durationForMode(mode)) {
      return;
    }
    _timer?.cancel();
    isTimerRunning = false;
    currentMode = mode;
    _resetDuration();
    notifyListeners();
  }

  void switchToNextMode() {
    switch (currentMode) {
      case 'Focus':
        setMode('Short Break');
        return;
      case 'Short Break':
        setMode('Long Break');
        return;
      default:
        setMode('Focus');
        return;
    }
  }

  String get timerDisplay {
    final minutes = (remainingTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingTime % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress =>
      _currentDuration == 0 ? 0 : remainingTime / _currentDuration;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
