import 'focus_session.dart';
import 'task.dart';

enum DailyCapacity { low, medium, high }

enum DailyPlanAction {
  startTiny,
  startFocus,
  shrinkFirst,
  resume,
  moveLater,
}

class DailyPlanTaskInsight {
  const DailyPlanTaskInsight({
    required this.action,
    required this.reason,
    required this.detail,
    required this.badgeLabel,
    this.resumeSession,
    this.targetTitle,
  });

  final DailyPlanAction action;
  final String reason;
  final String detail;
  final String badgeLabel;
  final FocusSession? resumeSession;
  final String? targetTitle;

  bool get isResume => action == DailyPlanAction.resume;
  bool get needsSmallerStep => action == DailyPlanAction.shrinkFirst;
}

class PlannedTask {
  const PlannedTask({
    required this.task,
    required this.insight,
    required this.score,
  });

  final Task task;
  final DailyPlanTaskInsight insight;
  final int score;
}

class DailyPlan {
  const DailyPlan({
    required this.plannedTasks,
  });

  final List<PlannedTask> plannedTasks;

  Task? get nowTask => plannedTasks.isEmpty ? null : plannedTasks.first.task;

  List<Task> get nextTasks {
    return List.unmodifiable(plannedTasks.skip(1).take(2).map((item) {
      return item.task;
    }));
  }

  int get laterCount {
    final remaining = plannedTasks.length - 3;
    return remaining < 0 ? 0 : remaining;
  }

  DailyPlanTaskInsight? insightFor(int taskId) {
    for (final plannedTask in plannedTasks) {
      if (plannedTask.task.id == taskId) return plannedTask.insight;
    }
    return null;
  }

  PlannedTask? get resumeSuggestion {
    for (final plannedTask in plannedTasks) {
      if (plannedTask.insight.isResume) return plannedTask;
    }
    return null;
  }
}
