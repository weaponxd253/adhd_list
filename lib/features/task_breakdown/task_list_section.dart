import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/subtask.dart';
import '../../models/task.dart';
import '../../providers/task_state.dart';
import '../../theme/app_theme.dart';

class TaskListSection extends StatefulWidget {
  const TaskListSection({super.key, required this.taskState});

  final TaskState taskState;

  @override
  State<TaskListSection> createState() => _TaskListSectionState();
}

class _TaskListSectionState extends State<TaskListSection> {
  final Map<int, TextEditingController> _subtaskControllers = {};
  final Set<int> _expandedTaskIds = {};
  bool _showCompleted = false;

  @override
  void dispose() {
    for (final controller in _subtaskControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _subtaskController(int taskId) {
    return _subtaskControllers.putIfAbsent(
      taskId,
      TextEditingController.new,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.taskState.tasks
        .where((task) => !task.isCompleted)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final completed =
        widget.taskState.tasks.where((task) => task.isCompleted).toList()
          ..sort((a, b) {
            final aDate = a.completedAt ?? DateTime(1970);
            final bDate = b.completedAt ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });

    if (pending.isEmpty && completed.isEmpty) {
      return const _EmptyTasks();
    }

    return ListView(
      key: const PageStorageKey('task-list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: [
        _SectionHeader(
          title: 'To do',
          count: pending.length,
          icon: Icons.radio_button_unchecked_rounded,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (pending.isEmpty)
          const _SectionEmpty(message: 'Everything is complete for now.')
        else
          ...pending.map(_buildTaskCard),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionHeader(
            title: 'Completed',
            count: completed.length,
            icon: Icons.check_circle_outline_rounded,
            expanded: _showCompleted,
            onTap: () => setState(() => _showCompleted = !_showCompleted),
          ),
          if (_showCompleted) ...[
            const SizedBox(height: AppSpacing.xs),
            ...completed.map(_buildTaskCard),
          ],
        ],
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    final expanded = _expandedTaskIds.contains(task.id);
    final busy = widget.taskState.isTaskBusy(task.id);
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final statusColor = task.isCompleted
        ? semantic.success
        : _dayDifference(task.dueDate) < 0
            ? semantic.danger
            : _dayDifference(task.dueDate) <= 1
                ? semantic.warning
                : Theme.of(context).colorScheme.primary;
    final compactActions = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return Padding(
      key: ValueKey('task-${task.id}'),
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (busy) const LinearProgressIndicator(minHeight: 2),
            Semantics(
              container: true,
              label:
                  '${task.title}, ${_dueDescription(task)}, ${task.isCompleted ? "completed" : "not completed"}',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(width: 4, height: 76, color: statusColor),
                  Checkbox(
                    key: ValueKey('complete-task-${task.id}'),
                    value: task.isCompleted,
                    onChanged: busy
                        ? null
                        : (_) => _run(
                              () => widget.taskState
                                  .toggleTaskCompletion(task.id),
                            ),
                    semanticLabel: task.isCompleted
                        ? 'Mark ${task.title} incomplete'
                        : 'Mark ${task.title} complete',
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        expanded
                            ? _expandedTaskIds.remove(task.id)
                            : _expandedTaskIds.add(task.id);
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xxs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _StatusBadge(
                                  label: _dueBadge(task),
                                  color: statusColor,
                                  icon: task.isCompleted
                                      ? Icons.check_rounded
                                      : _dayDifference(task.dueDate) < 0
                                          ? Icons.warning_amber_rounded
                                          : Icons.calendar_today_outlined,
                                ),
                                if (task.subtasks.isNotEmpty)
                                  Text(
                                    '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length} steps',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (compactActions)
                    PopupMenuButton<String>(
                      tooltip: 'Task actions for ${task.title}',
                      enabled: !busy,
                      onSelected: (value) {
                        if (value == 'edit') _showEditTask(task);
                        if (value == 'delete') _deleteWithUndo(task);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: semantic.danger,
                            ),
                            title: const Text('Delete'),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    IconButton(
                      tooltip: 'Edit ${task.title}',
                      onPressed: busy ? null : () => _showEditTask(task),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete ${task.title}',
                      onPressed: busy ? null : () => _deleteWithUndo(task),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: semantic.danger,
                      ),
                    ),
                  ],
                  IconButton(
                    tooltip: expanded ? 'Collapse task' : 'Expand task',
                    onPressed: () => setState(() {
                      expanded
                          ? _expandedTaskIds.remove(task.id)
                          : _expandedTaskIds.add(task.id);
                    }),
                    icon: Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                  ),
                ],
              ),
            ),
            if (expanded) _buildSubtasks(task, busy),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtasks(Task task, bool busy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          for (final subtask in task.subtasks)
            _SubtaskRow(
              key: ValueKey('subtask-${subtask.id}'),
              subtask: subtask,
              enabled: !busy,
              onToggle: () => _run(
                () => widget.taskState
                    .toggleSubtaskCompletion(task.id, subtask.id),
              ),
              onEdit: () => _showEditSubtask(task, subtask),
              onDelete: () => _run(
                () => widget.taskState.deleteSubtask(task.id, subtask.id),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('add-subtask-field-${task.id}'),
                  controller: _subtaskController(task.id),
                  enabled: !busy,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addSubtask(task),
                  decoration: const InputDecoration(
                    hintText: 'Add a step',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton.filled(
                key: ValueKey('add-subtask-button-${task.id}'),
                tooltip: 'Add step',
                onPressed: busy ? null : () => _addSubtask(task),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addSubtask(Task task) async {
    final controller = _subtaskController(task.id);
    final title = controller.text.trim();
    if (title.isEmpty) {
      _message('Enter a step name');
      return;
    }
    final succeeded = await _run(
      () => widget.taskState.addSubtask(task.id, title),
    );
    if (succeeded) controller.clear();
  }

  Future<void> _deleteWithUndo(Task task) async {
    try {
      final deleted = await widget.taskState.deleteTask(task.id);
      if (!mounted) return;
      _subtaskControllers.remove(task.id)?.dispose();
      _expandedTaskIds.remove(task.id);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${task.title} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                unawaited(_restoreTask(deleted));
              },
            ),
          ),
        );
    } catch (_) {
      _message('Could not delete the task. Try again.');
    }
  }

  Future<void> _restoreTask(Task task) async {
    try {
      await widget.taskState.restoreTask(task);
      if (mounted) _message('${task.title} restored');
    } catch (_) {
      if (mounted) _message('Could not restore the task.');
    }
  }

  Future<bool> _run(Future<void> Function() operation) async {
    try {
      await operation();
      return true;
    } catch (_) {
      if (mounted) _message('Could not save that change. Try again.');
      return false;
    }
  }

  void _showEditTask(Task task) {
    final controller = TextEditingController(text: task.title);
    var selectedDate = task.dueDate;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Task name'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateUtils.dateOnly(DateTime.now()),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isEmpty) {
                  _message('Task name cannot be blank');
                  return;
                }
                final success = await _run(
                  () => widget.taskState.editTask(task.id, title, selectedDate),
                );
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void _showEditSubtask(Task task, Subtask subtask) {
    final controller = TextEditingController(text: subtask.title);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit step'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Step name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) {
                _message('Step name cannot be blank');
                return;
              }
              final success = await _run(
                () => widget.taskState.editSubtask(task.id, subtask.id, title),
              );
              if (success && dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int _dayDifference(DateTime date) {
    return DateUtils.dateOnly(date)
        .difference(DateUtils.dateOnly(DateTime.now()))
        .inDays;
  }

  String _dueBadge(Task task) {
    if (task.isCompleted) return 'Done';
    final difference = _dayDifference(task.dueDate);
    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    return '${task.dueDate.month}/${task.dueDate.day}';
  }

  String _dueDescription(Task task) {
    if (task.isCompleted) return 'completed';
    final difference = _dayDifference(task.dueDate);
    if (difference < 0) return 'overdue';
    if (difference == 0) return 'due today';
    if (difference == 1) return 'due tomorrow';
    return 'due ${task.dueDate.month}/${task.dueDate.day}';
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    super.key,
    required this.subtask,
    required this.enabled,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Subtask subtask;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${subtask.title}, ${subtask.isCompleted ? "completed" : "not completed"}',
      child: Row(
        children: [
          Container(
            width: 2,
            height: 40,
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Checkbox(
            value: subtask.isCompleted,
            onChanged: enabled ? (_) => onToggle() : null,
            semanticLabel: subtask.isCompleted
                ? 'Mark ${subtask.title} incomplete'
                : 'Mark ${subtask.title} complete',
          ),
          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                decoration:
                    subtask.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit ${subtask.title}',
            onPressed: enabled ? onEdit : null,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Delete ${subtask.title}',
            onPressed: enabled ? onDelete : null,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    this.expanded,
    this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final bool? expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: AppSpacing.xs),
        Text('$count', style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        if (expanded != null)
          Icon(expanded! ? Icons.expand_less : Icons.expand_more),
      ],
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      expanded: expanded,
      label: '$title, $count tasks',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.control),
        onTap: onTap,
        child: SizedBox(
          height: AppSizes.minimumTouchTarget,
          child: content,
        ),
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add one above and break it into manageable steps.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
