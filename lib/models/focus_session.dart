import 'package:flutter/foundation.dart';

@immutable
class FocusSession {
  const FocusSession({
    this.id,
    required this.mode,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    this.completed = true,
    this.taskId,
    this.subtaskId,
    this.targetType = 'none',
    this.targetTitleSnapshot,
    this.outcome,
  });

  final int? id;
  final String mode;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final bool completed;
  final int? taskId;
  final int? subtaskId;
  final String targetType;
  final String? targetTitleSnapshot;
  final String? outcome;

  int get durationMinutes => (durationSeconds / 60).round();

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'mode': mode,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration_seconds': durationSeconds,
      'completed': completed ? 1 : 0,
      'task_id': taskId,
      'subtask_id': subtaskId,
      'target_type': targetType,
      'target_title_snapshot': targetTitleSnapshot,
      'outcome': outcome,
    };
  }

  factory FocusSession.fromMap(Map<String, Object?> map) {
    return FocusSession(
      id: map['id'] as int?,
      mode: map['mode'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: DateTime.parse(map['ended_at'] as String),
      durationSeconds: map['duration_seconds'] as int,
      completed: (map['completed'] as int? ?? 1) == 1,
      taskId: map['task_id'] as int?,
      subtaskId: map['subtask_id'] as int?,
      targetType: map['target_type'] as String? ?? 'none',
      targetTitleSnapshot: map['target_title_snapshot'] as String?,
      outcome: map['outcome'] as String?,
    );
  }
}
