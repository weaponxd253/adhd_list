import 'task.dart';

enum TaskReminderStyle {
  gentle('gentle', 'Gentle'),
  direct('direct', 'Direct'),
  tinyStep('tinyStep', 'Tiny step');

  const TaskReminderStyle(this.id, this.label);

  final String id;
  final String label;

  static TaskReminderStyle fromId(String? id) {
    for (final style in values) {
      if (style.id == id) return style;
    }
    return TaskReminderStyle.gentle;
  }

  String titleFor(Task task) {
    switch (this) {
      case TaskReminderStyle.gentle:
        return 'Gentle task nudge';
      case TaskReminderStyle.direct:
        return 'Task reminder';
      case TaskReminderStyle.tinyStep:
        return 'Tiny step waiting';
    }
  }

  String bodyFor(Task task, String tinyStep) {
    switch (this) {
      case TaskReminderStyle.gentle:
        return 'Still worth doing: ${task.title}. Start wherever is easiest.';
      case TaskReminderStyle.direct:
        return 'Open ${task.title}. One visible next move is enough.';
      case TaskReminderStyle.tinyStep:
        return tinyStep;
    }
  }
}

class TaskReminder {
  const TaskReminder({
    required this.taskId,
    required this.style,
    required this.scheduledAt,
    this.enabled = true,
  });

  final int taskId;
  final TaskReminderStyle style;
  final DateTime scheduledAt;
  final bool enabled;

  factory TaskReminder.fromMap(Map<String, dynamic> map) {
    return TaskReminder(
      taskId: map['task_id'] as int,
      style: TaskReminderStyle.fromId(map['style'] as String?),
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      enabled: map['enabled'] != 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'task_id': taskId,
      'style': style.id,
      'scheduled_at': scheduledAt.toIso8601String(),
      'enabled': enabled ? 1 : 0,
    };
  }
}
