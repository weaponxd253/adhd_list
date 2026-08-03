import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../database/timer_session_database.dart';
import '../models/focus_session.dart';
import '../repositories/repositories.dart';
import '../services/timer_notification_service.dart';

class TimerState extends ChangeNotifier {
  TimerState({
    DateTime Function()? now,
    TimerSessionRepository? sessionRepository,
    TimerNotificationService? notificationService,
    bool autoLoadHistory = false,
  })  : _now = now ?? DateTime.now,
        _sessionRepository = sessionRepository ?? TimerSessionDatabase(),
        _notificationService =
            notificationService ?? const NoopTimerNotificationService() {
    _resetDuration();
    if (autoLoadHistory) unawaited(loadSessionHistory());
  }

  bool isTimerRunning = false;
  String currentMode = 'Focus';
  int remainingTime = 0;
  int focusDuration = 25;
  int shortBreakDuration = 5;
  int longBreakDuration = 15;

  int _currentDuration = 0;
  final DateTime Function() _now;
  final TimerSessionRepository _sessionRepository;
  final TimerNotificationService _notificationService;
  final List<FocusSession> _sessions = [];
  String? _completionMessage;
  String? _lastCompletedMode;
  String? _sessionHistoryError;
  DateTime? _sessionStartedAt;
  DateTime? _sessionEndsAt;
  int? _sessionPlannedDurationSeconds;
  Timer? _timer;
  bool _isSessionHistoryLoading = false;
  bool _notificationsEnabled = false;
  bool _notificationPermissionGranted = false;
  bool _disposed = false;

  String? get completionMessage => _completionMessage;
  UnmodifiableListView<FocusSession> get sessionHistory =>
      UnmodifiableListView(_sessions);
  bool get isSessionHistoryLoading => _isSessionHistoryLoading;
  String? get sessionHistoryError => _sessionHistoryError;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get notificationPermissionGranted => _notificationPermissionGranted;
  bool get notificationPermissionNeeded =>
      _notificationsEnabled && !_notificationPermissionGranted;

  String get statusLabel {
    if (isTimerRunning) return 'Session in progress';
    if (_lastCompletedMode != null) return '$currentMode ready';
    if (remainingTime < _currentDuration) return 'Paused';
    return 'Ready to start';
  }

  int get completedSessionsToday {
    final today = _now();
    return _sessions.where((session) {
      return session.completed && _isSameDay(session.endedAt, today);
    }).length;
  }

  int get focusMinutesToday {
    final today = _now();
    final seconds = _sessions.where((session) {
      return session.completed &&
          session.mode == 'Focus' &&
          _isSameDay(session.endedAt, today);
    }).fold<int>(0, (total, session) => total + session.durationSeconds);
    return seconds ~/ 60;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
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
    _sessionStartedAt ??= _now();
    _sessionPlannedDurationSeconds ??= _currentDuration;
    isTimerRunning = true;
    _sessionEndsAt = _now().add(Duration(seconds: remainingTime));
    _startTicker();
    unawaited(_scheduleCompletionNotification());
    notifyListeners();
  }

  void startQuickFocus(int minutes) {
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'Must be greater than 0');
    }
    _timer?.cancel();
    _timer = null;
    _clearCompletionState();
    _clearSessionTracking();
    currentMode = 'Focus';
    _currentDuration = minutes * 60;
    remainingTime = _currentDuration;
    startTimer();
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _sessionEndsAt = null;
    _clearSessionTracking();
    isTimerRunning = false;
    _clearCompletionState();
    _resetDuration();
    unawaited(_notificationService.cancelTimerCompletion());
    notifyListeners();
  }

  void pauseTimer() {
    if (!isTimerRunning) return;
    syncWithClock(notify: false);
    if (!isTimerRunning) return;
    _timer?.cancel();
    _timer = null;
    _sessionEndsAt = null;
    isTimerRunning = false;
    unawaited(_notificationService.cancelTimerCompletion());
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = null;
    _sessionEndsAt = null;
    _clearSessionTracking();
    isTimerRunning = false;
    _clearCompletionState();
    _resetDuration();
    unawaited(_notificationService.cancelTimerCompletion());
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
      _clearSessionTracking();
      _resetDuration();
    }
    notifyListeners();
  }

  void updateSettings({
    required int focus,
    required int shortBreak,
    required int longBreak,
    required bool notificationsEnabled,
  }) {
    updateDurations(
      focus: focus,
      shortBreak: shortBreak,
      longBreak: longBreak,
    );

    if (_notificationsEnabled == notificationsEnabled) return;
    _notificationsEnabled = notificationsEnabled;
    if (_notificationsEnabled) {
      if (isTimerRunning) unawaited(_scheduleCompletionNotification());
    } else {
      _notificationPermissionGranted = false;
      unawaited(_notificationService.cancelTimerCompletion());
    }
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    if (!_notificationsEnabled) {
      if (_notificationPermissionGranted) {
        _notificationPermissionGranted = false;
        notifyListeners();
      }
      return false;
    }

    final granted = await _requestNotificationPermission();
    if (granted && isTimerRunning) {
      await _scheduleCompletionNotification(ensurePermission: false);
    }
    return granted;
  }

  Future<bool> _requestNotificationPermission() async {
    final granted = await _notificationService.requestPermission();
    if (_disposed) return false;

    if (_notificationPermissionGranted != granted) {
      _notificationPermissionGranted = granted;
      notifyListeners();
    }
    return granted;
  }

  void setMode(String mode) {
    if (!isTimerRunning &&
        mode == currentMode &&
        remainingTime == _durationForMode(mode)) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    _sessionEndsAt = null;
    _clearSessionTracking();
    isTimerRunning = false;
    _clearCompletionState();
    currentMode = mode;
    _resetDuration();
    unawaited(_notificationService.cancelTimerCompletion());
    notifyListeners();
  }

  void switchToNextMode() {
    setMode(_nextModeFor(currentMode));
  }

  void syncWithClock({bool notify = true}) {
    if (!isTimerRunning || _sessionEndsAt == null) return;

    final remainingMs = _sessionEndsAt!.difference(_now()).inMilliseconds;
    if (remainingMs <= 0) {
      _completeSession();
      return;
    }

    final nextRemaining = (remainingMs + 999) ~/ 1000;
    if (nextRemaining == remainingTime) return;

    remainingTime =
        nextRemaining > _currentDuration ? _currentDuration : nextRemaining;
    if (notify) notifyListeners();
  }

  void clearCompletionMessage() {
    if (_completionMessage == null) return;
    _completionMessage = null;
    notifyListeners();
  }

  Future<void> loadSessionHistory({int limit = 60}) async {
    _isSessionHistoryLoading = true;
    _sessionHistoryError = null;
    notifyListeners();

    try {
      final rows = await _sessionRepository.fetchSessions(limit: limit);
      if (_disposed) return;
      _sessions
        ..clear()
        ..addAll(rows.map(FocusSession.fromMap));
    } catch (_) {
      if (_disposed) return;
      _sessionHistoryError = 'Could not load timer history.';
    } finally {
      if (!_disposed) {
        _isSessionHistoryLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> clearSessionHistory() async {
    await _sessionRepository.clearSessions();
    _sessions.clear();
    notifyListeners();
  }

  void _completeSession() {
    final completedMode = currentMode;
    final endedAt = _sessionEndsAt ?? _now();
    final startedAt = _sessionStartedAt ??
        endedAt.subtract(Duration(seconds: _currentDuration));
    final durationSeconds = _sessionPlannedDurationSeconds ?? _currentDuration;
    _timer?.cancel();
    _timer = null;
    _sessionEndsAt = null;
    _clearSessionTracking();
    isTimerRunning = false;
    currentMode = _nextModeFor(currentMode);
    _lastCompletedMode = completedMode;
    _completionMessage = '$completedMode complete. $currentMode ready.';
    _resetDuration();
    unawaited(_notificationService.cancelTimerCompletion());
    unawaited(
      _recordCompletedSession(
        mode: completedMode,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSeconds: durationSeconds,
      ),
    );
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

  void _clearSessionTracking() {
    _sessionStartedAt = null;
    _sessionPlannedDurationSeconds = null;
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => syncWithClock(),
    );
  }

  Future<void> _recordCompletedSession({
    required String mode,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
  }) async {
    final session = FocusSession(
      mode: mode,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: durationSeconds,
    );

    try {
      final id = await _sessionRepository.insertSession(session.toMap());
      if (_disposed) return;
      _sessions.insert(
        0,
        FocusSession(
          id: id,
          mode: session.mode,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          durationSeconds: session.durationSeconds,
          completed: session.completed,
        ),
      );
      notifyListeners();
    } catch (_) {
      if (_disposed) return;
      _sessionHistoryError = 'Could not save timer session.';
      notifyListeners();
    }
  }

  Future<void> _scheduleCompletionNotification({
    bool ensurePermission = true,
  }) async {
    final when = _sessionEndsAt;
    if (!_notificationsEnabled || when == null) return;

    final mode = currentMode;
    final nextMode = _nextModeFor(mode);
    final granted = ensurePermission
        ? await _requestNotificationPermission()
        : _notificationPermissionGranted;
    if (_disposed || !granted) return;

    await _notificationService.scheduleTimerCompletion(
      when: when,
      title: '$mode complete',
      body: '$nextMode ready.',
    );
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
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
