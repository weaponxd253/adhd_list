import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../database/timer_session_database.dart';
import '../models/focus_session.dart';
import '../repositories/repositories.dart';
import '../services/timer_notification_service.dart';

@immutable
class TimerCompletionTarget {
  const TimerCompletionTarget({
    required this.completionId,
    required this.taskId,
    required this.targetType,
    required this.title,
    this.sessionId,
    this.subtaskId,
  });

  final int completionId;
  final int? sessionId;
  final int taskId;
  final int? subtaskId;
  final String targetType;
  final String title;

  bool get isSubtask => targetType == TimerState.targetTypeSubtask;

  TimerCompletionTarget copyWith({int? sessionId}) {
    return TimerCompletionTarget(
      completionId: completionId,
      sessionId: sessionId ?? this.sessionId,
      taskId: taskId,
      subtaskId: subtaskId,
      targetType: targetType,
      title: title,
    );
  }
}

class TimerState extends ChangeNotifier {
  static const targetTypeNone = 'none';
  static const targetTypeTask = 'task';
  static const targetTypeSubtask = 'subtask';
  static const outcomeTimeDoneOnly = 'time_done_only';
  static const outcomeTaskCompleted = 'task_completed';
  static const outcomeSubtaskCompleted = 'subtask_completed';
  static const outcomeContinued = 'continued';
  static const outcomeLeftOpen = 'left_open';
  static const outcomeBreakReady = 'break_ready';

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
  int? _activeTaskId;
  int? _activeSubtaskId;
  String _activeTargetType = targetTypeNone;
  String? _activeTargetTitle;
  TimerCompletionTarget? _pendingCompletionTarget;
  final Map<int, String> _queuedCompletionOutcomes = {};
  int _nextCompletionId = 1;
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
  int? get activeTaskId => _activeTaskId;
  int? get activeSubtaskId => _activeSubtaskId;
  String get activeTargetType => _activeTargetType;
  String? get activeTargetTitle => _activeTargetTitle;
  bool get hasActiveTarget => _activeTargetType != targetTypeNone;
  bool get hasActiveSession => _sessionStartedAt != null;
  bool get isActiveFocusSession => hasActiveSession && currentMode == 'Focus';
  TimerCompletionTarget? get pendingCompletionTarget =>
      _pendingCompletionTarget;

  bool isActiveForTask(int taskId) {
    return isActiveFocusSession && _activeTaskId == taskId;
  }

  bool isActiveForSubtask(int subtaskId) {
    return isActiveFocusSession && _activeSubtaskId == subtaskId;
  }

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

  bool startQuickFocus(int minutes) {
    return startTargetFocus(
      minutes: minutes,
      targetType: targetTypeNone,
    );
  }

  bool startTargetFocus({
    required int minutes,
    required String targetType,
    int? taskId,
    int? subtaskId,
    String? title,
  }) {
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'Must be greater than 0');
    }
    _validateTarget(
      targetType: targetType,
      taskId: taskId,
      subtaskId: subtaskId,
    );
    syncWithClock(notify: false);
    if (hasActiveSession) return false;

    _timer?.cancel();
    _timer = null;
    _clearCompletionState();
    _clearSessionTracking();
    _setActiveTarget(
      targetType: targetType,
      taskId: taskId,
      subtaskId: subtaskId,
      title: title,
    );
    currentMode = 'Focus';
    _currentDuration = minutes * 60;
    remainingTime = _currentDuration;
    startTimer();
    return true;
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

  bool endCurrentSessionEarly() {
    syncWithClock(notify: false);
    if (!hasActiveSession) return false;

    final completedMode = currentMode;
    final plannedDuration = _sessionPlannedDurationSeconds ?? _currentDuration;
    final rawElapsed = plannedDuration - remainingTime;
    final durationSeconds = rawElapsed < 0
        ? 0
        : rawElapsed > plannedDuration
            ? plannedDuration
            : rawElapsed;
    final endedAt = _now();
    final startedAt = _sessionStartedAt ??
        endedAt.subtract(Duration(seconds: durationSeconds));
    final nextMode = _nextModeFor(completedMode);

    _finishSession(
      completedMode: completedMode,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: durationSeconds,
      completionText: '$completedMode ended. $nextMode ready.',
    );
    return true;
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

  Future<void> resolveLinkedCompletion(String outcome) async {
    final target = _pendingCompletionTarget;
    if (target == null) return;

    _pendingCompletionTarget = null;
    _completionMessage = null;

    final sessionId = target.sessionId;
    if (sessionId == null) {
      _queuedCompletionOutcomes[target.completionId] = outcome;
      notifyListeners();
      return;
    }

    await _updateRecordedSessionOutcome(sessionId, outcome);
    notifyListeners();
  }

  Future<bool> continueLinkedFocus({int minutes = 5}) async {
    final target = _pendingCompletionTarget;
    if (target == null) return false;

    await resolveLinkedCompletion(outcomeContinued);
    return startTargetFocus(
      minutes: minutes,
      targetType: target.targetType,
      taskId: target.taskId,
      subtaskId: target.subtaskId,
      title: target.title,
    );
  }

  void _completeSession() {
    final completedMode = currentMode;
    final endedAt = _sessionEndsAt ?? _now();
    final startedAt = _sessionStartedAt ??
        endedAt.subtract(Duration(seconds: _currentDuration));
    final durationSeconds = _sessionPlannedDurationSeconds ?? _currentDuration;
    final nextMode = _nextModeFor(completedMode);

    _finishSession(
      completedMode: completedMode,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: durationSeconds,
      completionText: '$completedMode complete. $nextMode ready.',
    );
  }

  void _finishSession({
    required String completedMode,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
    required String completionText,
  }) {
    final taskId = _activeTaskId;
    final subtaskId = _activeSubtaskId;
    final targetType = _activeTargetType;
    final targetTitleSnapshot = _activeTargetTitle;
    final completionId = _nextCompletionId++;
    final pendingTarget = _targetForCompletedSession(
      completionId: completionId,
      completedMode: completedMode,
      taskId: taskId,
      subtaskId: subtaskId,
      targetType: targetType,
      targetTitleSnapshot: targetTitleSnapshot,
    );
    _timer?.cancel();
    _timer = null;
    _sessionEndsAt = null;
    _clearSessionTracking();
    isTimerRunning = false;
    currentMode = _nextModeFor(completedMode);
    _lastCompletedMode = completedMode;
    _completionMessage = completionText;
    _pendingCompletionTarget = pendingTarget;
    _resetDuration();
    unawaited(_notificationService.cancelTimerCompletion());
    unawaited(
      _recordCompletedSession(
        mode: completedMode,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSeconds: durationSeconds,
        taskId: taskId,
        subtaskId: subtaskId,
        targetType: targetType,
        targetTitleSnapshot: targetTitleSnapshot,
        outcome: outcomeTimeDoneOnly,
        completionId: pendingTarget == null ? null : completionId,
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
    _pendingCompletionTarget = null;
  }

  TimerCompletionTarget? _targetForCompletedSession({
    required int completionId,
    required String completedMode,
    required int? taskId,
    required int? subtaskId,
    required String targetType,
    required String? targetTitleSnapshot,
  }) {
    if (completedMode != 'Focus') return null;
    if (targetType != targetTypeTask && targetType != targetTypeSubtask) {
      return null;
    }
    if (taskId == null) return null;
    if (targetType == targetTypeSubtask && subtaskId == null) return null;

    final fallbackTitle =
        targetType == targetTypeSubtask ? 'This step' : 'This task';
    final title = targetTitleSnapshot?.trim();
    return TimerCompletionTarget(
      completionId: completionId,
      taskId: taskId,
      subtaskId: subtaskId,
      targetType: targetType,
      title: title == null || title.isEmpty ? fallbackTitle : title,
    );
  }

  void _clearSessionTracking() {
    _sessionStartedAt = null;
    _sessionPlannedDurationSeconds = null;
    _activeTaskId = null;
    _activeSubtaskId = null;
    _activeTargetType = targetTypeNone;
    _activeTargetTitle = null;
  }

  void _validateTarget({
    required String targetType,
    required int? taskId,
    required int? subtaskId,
  }) {
    switch (targetType) {
      case targetTypeNone:
        return;
      case targetTypeTask:
        if (taskId == null) {
          throw ArgumentError.value(taskId, 'taskId', 'Required for task');
        }
        return;
      case targetTypeSubtask:
        if (taskId == null) {
          throw ArgumentError.value(taskId, 'taskId', 'Required for subtask');
        }
        if (subtaskId == null) {
          throw ArgumentError.value(
            subtaskId,
            'subtaskId',
            'Required for subtask',
          );
        }
        return;
      default:
        throw ArgumentError.value(
          targetType,
          'targetType',
          'Must be none, task, or subtask',
        );
    }
  }

  void _setActiveTarget({
    required String targetType,
    int? taskId,
    int? subtaskId,
    String? title,
  }) {
    if (targetType == targetTypeNone) {
      _activeTaskId = null;
      _activeSubtaskId = null;
      _activeTargetType = targetTypeNone;
      _activeTargetTitle = null;
      return;
    }

    _activeTaskId = taskId;
    _activeSubtaskId = subtaskId;
    _activeTargetType = targetType;
    final trimmedTitle = title?.trim();
    _activeTargetTitle =
        trimmedTitle == null || trimmedTitle.isEmpty ? null : trimmedTitle;
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
    int? taskId,
    int? subtaskId,
    String targetType = targetTypeNone,
    String? targetTitleSnapshot,
    String? outcome,
    int? completionId,
  }) async {
    final session = FocusSession(
      mode: mode,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: durationSeconds,
      taskId: taskId,
      subtaskId: subtaskId,
      targetType: targetType,
      targetTitleSnapshot: targetTitleSnapshot,
      outcome: outcome,
    );

    try {
      final id = await _sessionRepository.insertSession(session.toMap());
      if (_disposed) return;
      final queuedOutcome = completionId == null
          ? null
          : _queuedCompletionOutcomes.remove(completionId);
      final resolvedOutcome = queuedOutcome ?? session.outcome;
      _sessions.insert(
        0,
        FocusSession(
          id: id,
          mode: session.mode,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          durationSeconds: session.durationSeconds,
          completed: session.completed,
          taskId: session.taskId,
          subtaskId: session.subtaskId,
          targetType: session.targetType,
          targetTitleSnapshot: session.targetTitleSnapshot,
          outcome: resolvedOutcome,
        ),
      );
      if (completionId != null) {
        _attachSessionIdToPendingCompletion(completionId, id);
      }
      if (queuedOutcome != null) {
        await _sessionRepository.updateSessionOutcome(id, queuedOutcome);
      }
      notifyListeners();
    } catch (_) {
      if (_disposed) return;
      if (completionId != null) _queuedCompletionOutcomes.remove(completionId);
      _sessionHistoryError = 'Could not save timer session.';
      notifyListeners();
    }
  }

  void _attachSessionIdToPendingCompletion(int completionId, int sessionId) {
    final target = _pendingCompletionTarget;
    if (target == null || target.completionId != completionId) return;
    _pendingCompletionTarget = target.copyWith(sessionId: sessionId);
  }

  Future<void> _updateRecordedSessionOutcome(
    int sessionId,
    String outcome,
  ) async {
    try {
      await _sessionRepository.updateSessionOutcome(sessionId, outcome);
      final index = _sessions.indexWhere((session) => session.id == sessionId);
      if (index == -1) return;
      final session = _sessions[index];
      _sessions[index] = FocusSession(
        id: session.id,
        mode: session.mode,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        durationSeconds: session.durationSeconds,
        completed: session.completed,
        taskId: session.taskId,
        subtaskId: session.subtaskId,
        targetType: session.targetType,
        targetTitleSnapshot: session.targetTitleSnapshot,
        outcome: outcome,
      );
    } catch (_) {
      if (_disposed) return;
      _sessionHistoryError = 'Could not save timer session.';
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
