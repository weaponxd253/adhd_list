import '../models/daily_plan.dart';
import '../models/focus_session.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../providers/timer_state.dart';

class DailyPlanService {
  DailyPlanService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  DailyPlan build({
    required Iterable<Task> tasks,
    required TimerState timerState,
    required DailyCapacity capacity,
    required String mood,
  }) {
    final pendingTasks = tasks.where((task) => !task.isCompleted).toList();
    final openSessionsByTask = _openSessionsByTask(pendingTasks, timerState);
    final scoredTasks = [
      for (final task in pendingTasks)
        _scoreTask(
          task: task,
          openSession: openSessionsByTask[task.id],
          capacity: capacity,
          mood: mood,
          timerState: timerState,
        ),
    ]..sort(_compareScoredTasks);

    return DailyPlan(
      plannedTasks: List.unmodifiable(scoredTasks.map((item) {
        return PlannedTask(
          task: item.task,
          insight: item.insight,
          score: item.score,
        );
      })),
    );
  }

  int _compareScoredTasks(_ScoredTask first, _ScoredTask second) {
    final byScore = second.score.compareTo(first.score);
    if (byScore != 0) return byScore;

    final byDueDate = first.task.dueDate.compareTo(second.task.dueDate);
    if (byDueDate != 0) return byDueDate;

    return first.task.id.compareTo(second.task.id);
  }

  _ScoredTask _scoreTask({
    required Task task,
    required FocusSession? openSession,
    required DailyCapacity capacity,
    required String mood,
    required TimerState timerState,
  }) {
    final dayDifference = _calendarDayDifference(task.dueDate);
    final estimate = _effectiveEstimate(task);
    final hasOpenStep = _firstIncompleteSubtask(task) != null;
    final hasProgress = timerState.focusSummaryForTask(task.id).hasFocus ||
        task.subtasks.any((subtask) => subtask.isCompleted);
    final recoveryMood = _isRecoveryMood(mood);
    final isSmall = estimate != null && estimate <= 10;
    final isTiny = estimate != null && estimate <= 5;
    var score = 0;

    if (dayDifference < 0) {
      score += 120 + (-dayDifference).clamp(0, 5) * 6;
    } else if (dayDifference == 0) {
      score += 95;
    } else if (dayDifference == 1) {
      score += 35;
    } else {
      score += (20 - dayDifference).clamp(0, 20);
    }

    if (openSession != null) score += 85;
    if (hasProgress) score += 18;
    if (hasOpenStep) score += 12;

    switch (capacity) {
      case DailyCapacity.low:
        if (isTiny) {
          score += 70;
        } else if (isSmall) {
          score += 45;
        } else if (estimate == null && hasOpenStep) {
          score += 20;
        } else if (estimate == null || estimate > 25) {
          score -= dayDifference < 0 ? 35 : 55;
        }
        break;
      case DailyCapacity.medium:
        if (estimate != null && estimate <= 25) {
          score += 24;
        } else if (estimate != null && estimate > 45) {
          score -= 16;
        }
        break;
      case DailyCapacity.high:
        if (estimate == null || estimate >= 15) {
          score += 18;
        }
        if (dayDifference <= 1) score += 10;
        break;
    }

    if (recoveryMood) {
      if (isTiny) {
        score += 25;
      } else if (estimate == null || estimate > 25) {
        score -= 20;
      }
    }

    return _ScoredTask(
      task: task,
      score: score,
      insight: _insightFor(
        task: task,
        openSession: openSession,
        capacity: capacity,
        mood: mood,
        dayDifference: dayDifference,
        estimate: estimate,
        hasProgress: hasProgress,
      ),
    );
  }

  DailyPlanTaskInsight _insightFor({
    required Task task,
    required FocusSession? openSession,
    required DailyCapacity capacity,
    required String mood,
    required int dayDifference,
    required int? estimate,
    required bool hasProgress,
  }) {
    if (openSession != null) {
      final targetTitle = _targetTitle(task, openSession);
      return DailyPlanTaskInsight(
        action: DailyPlanAction.resume,
        reason: 'Left open',
        detail: 'Pick up where the last focus session stopped.',
        badgeLabel: 'Resume candidate',
        resumeSession: openSession,
        targetTitle: targetTitle,
      );
    }

    final shouldShrink = _shouldShrinkFirst(
      task: task,
      capacity: capacity,
      mood: mood,
      estimate: estimate,
    );
    if (shouldShrink) {
      return const DailyPlanTaskInsight(
        action: DailyPlanAction.shrinkFirst,
        reason: 'Shrink first',
        detail: 'Make the next step smaller before starting.',
        badgeLabel: 'Needs smaller step',
      );
    }

    if (capacity == DailyCapacity.low && estimate != null && estimate <= 10) {
      return const DailyPlanTaskInsight(
        action: DailyPlanAction.startTiny,
        reason: 'Small enough',
        detail: 'This matches low capacity today.',
        badgeLabel: 'Good low-capacity task',
      );
    }

    if (dayDifference < 0) {
      return const DailyPlanTaskInsight(
        action: DailyPlanAction.startFocus,
        reason: 'Overdue',
        detail: 'One focus block can get it moving again.',
        badgeLabel: 'Overdue',
      );
    }

    if (dayDifference == 0) {
      return const DailyPlanTaskInsight(
        action: DailyPlanAction.startFocus,
        reason: 'Due today',
        detail: 'One focus session keeps today clear.',
        badgeLabel: 'Due today',
      );
    }

    if (hasProgress) {
      return const DailyPlanTaskInsight(
        action: DailyPlanAction.startFocus,
        reason: 'Already started',
        detail: 'You have already made contact with it.',
        badgeLabel: 'Started',
      );
    }

    return const DailyPlanTaskInsight(
      action: DailyPlanAction.startFocus,
      reason: 'Good next step',
      detail: 'This is a reasonable next task.',
      badgeLabel: 'Good next step',
    );
  }

  bool _shouldShrinkFirst({
    required Task task,
    required DailyCapacity capacity,
    required String mood,
    required int? estimate,
  }) {
    final recoveryMode = capacity == DailyCapacity.low || _isRecoveryMood(mood);
    if (!recoveryMode) return false;
    if (_firstIncompleteSubtask(task) != null && estimate != null) {
      return estimate > 15;
    }
    return estimate == null || estimate > 15;
  }

  Map<int, FocusSession> _openSessionsByTask(
    List<Task> pendingTasks,
    TimerState timerState,
  ) {
    final taskIds = pendingTasks.map((task) => task.id).toSet();
    final tasksById = {for (final task in pendingTasks) task.id: task};
    final latestByTarget = <String, FocusSession>{};

    for (final session in timerState.sessionHistory) {
      final taskId = session.taskId;
      if (!_countsForPlanning(session) ||
          taskId == null ||
          !taskIds.contains(taskId)) {
        continue;
      }

      final targetKey =
          '$taskId:${session.targetType}:${session.subtaskId ?? 0}';
      final current = latestByTarget[targetKey];
      if (current == null || session.endedAt.isAfter(current.endedAt)) {
        latestByTarget[targetKey] = session;
      }
    }

    final openSessions = <int, FocusSession>{};
    for (final session in latestByTarget.values) {
      if (session.outcome != TimerState.outcomeLeftOpen) continue;

      final task = tasksById[session.taskId];
      if (task == null || !_targetStillOpen(task, session)) continue;

      final current = openSessions[task.id];
      if (current == null || session.endedAt.isAfter(current.endedAt)) {
        openSessions[task.id] = session;
      }
    }

    return openSessions;
  }

  bool _countsForPlanning(FocusSession session) {
    return session.completed &&
        session.mode == 'Focus' &&
        session.durationSeconds > 0 &&
        session.taskId != null &&
        (session.targetType == TimerState.targetTypeTask ||
            session.targetType == TimerState.targetTypeSubtask);
  }

  bool _targetStillOpen(Task task, FocusSession session) {
    if (session.targetType == TimerState.targetTypeTask) {
      return !task.isCompleted;
    }

    final subtaskId = session.subtaskId;
    if (subtaskId == null) return false;
    for (final subtask in task.subtasks) {
      if (subtask.id == subtaskId) return !subtask.isCompleted;
    }
    return false;
  }

  String _targetTitle(Task task, FocusSession session) {
    final snapshot = session.targetTitleSnapshot?.trim();
    if (snapshot != null && snapshot.isNotEmpty) return snapshot;

    if (session.targetType == TimerState.targetTypeSubtask) {
      final subtaskId = session.subtaskId;
      for (final subtask in task.subtasks) {
        if (subtask.id == subtaskId) return subtask.title;
      }
    }

    return task.title;
  }

  int? _effectiveEstimate(Task task) {
    if (task.estimatedMinutes != null) return task.estimatedMinutes;

    final subtask = _firstIncompleteSubtask(task);
    return subtask?.estimatedMinutes;
  }

  Subtask? _firstIncompleteSubtask(Task task) {
    for (final subtask in task.subtasks) {
      if (!subtask.isCompleted) return subtask;
    }
    return null;
  }

  bool _isRecoveryMood(String mood) {
    switch (mood) {
      case 'Anxious':
      case 'Worried':
      case 'Triggered':
      case 'Burnt Out':
      case 'Sad':
      case 'Grieving':
        return true;
      default:
        return false;
    }
  }

  int _calendarDayDifference(DateTime date) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(date.year, date.month, date.day).difference(today).inDays;
  }
}

class _ScoredTask {
  const _ScoredTask({
    required this.task,
    required this.score,
    required this.insight,
  });

  final Task task;
  final int score;
  final DailyPlanTaskInsight insight;
}
