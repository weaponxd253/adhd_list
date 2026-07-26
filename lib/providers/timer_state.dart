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
  String? _completionMessage;
  String? _lastCompletedMode;
  Timer? _timer;

  String? get completionMessage => _completionMessage;

  String get statusLabel {
    if (isTimerRunning) return 'Session in progress';
    if (_lastCompletedMode != null) return '$currentMode ready';
    if (remainingTime < _currentDuration) return 'Paused';
    return 'Ready to start';
  }

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
    _clearCompletionState();
    isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingTime > 1) {
        remainingTime--;
        notifyListeners();
      } else {
        _completeSession();
      }
    });
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    isTimerRunning = false;
    _clearCompletionState();
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
    _clearCompletionState();
    _resetDuration();
    notifyListeners();
  }

  void updateDurations({
    required int focus,
    required int shortBreak,
    required int longBreak,
  }) {
    final changed = focusDuration != focus ||
        shortBreakDuration != shortBreak ||
        longBreakDuration != longBreak;
    if (!changed) return;

    focusDuration = focus;
    shortBreakDuration = shortBreak;
    longBreakDuration = longBreak;
    _clearCompletionState();

    if (!isTimerRunning) {
      _resetDuration();
    }
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
    _clearCompletionState();
    currentMode = mode;
    _resetDuration();
    notifyListeners();
  }

  void switchToNextMode() {
    setMode(_nextModeFor(currentMode));
  }

  void clearCompletionMessage() {
    if (_completionMessage == null) return;
    _completionMessage = null;
    notifyListeners();
  }

  void _completeSession() {
    final completedMode = currentMode;
    _timer?.cancel();
    isTimerRunning = false;
    currentMode = _nextModeFor(currentMode);
    _lastCompletedMode = completedMode;
    _completionMessage = '$completedMode complete. $currentMode ready.';
    _resetDuration();
    notifyListeners();
  }

  String _nextModeFor(String mode) {
    switch (mode) {
      case 'Focus':
        return 'Short Break';
      case 'Short Break':
        return 'Long Break';
      default:
        return 'Focus';
    }
  }

  void _clearCompletionState() {
    _completionMessage = null;
    _lastCompletedMode = null;
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
