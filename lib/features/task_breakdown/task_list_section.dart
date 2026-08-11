import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/subtask.dart';
import '../../models/task.dart';
import '../../models/task_support.dart';
import '../../providers/settings_state.dart';
import '../../providers/task_reminder_state.dart';
import '../../providers/task_state.dart';
import '../../providers/timer_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_support_sheet.dart';

class TaskListSection extends StatefulWidget {
  const TaskListSection({super.key, required this.taskState});

  final TaskState taskState;

  @override
  State<TaskListSection> createState() => _TaskListSectionState();
}

class _TaskListSectionState extends State<TaskListSection> {
  final Map<int, TextEditingController> _subtaskControllers = {};
  final Set<int> _expandedTaskIds = {};
  bool _showLater = false;
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
    final nowTask = widget.taskState.nowTask;
    final nextTasks = widget.taskState.nextTasks;
    final laterTasks = widget.taskState.laterTasks;
    final completed = widget.taskState.completedTaskList;

    if (widget.taskState.tasks.isEmpty) {
      return const _EmptyTasks();
    }

    return ListView(
      key: const PageStorageKey('task-list'),
      padding: AppInsets.screenScrollPadding(
        context,
        left: AppSpacing.md,
        top: AppSpacing.xs,
        right: AppSpacing.md,
      ),
      children: [
        _SectionHeader(
          title: 'Now',
          count: nowTask == null ? 0 : 1,
          icon: Icons.flag_outlined,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (nowTask == null)
          const _SectionEmpty(
            message: "Nothing urgent. Pick one small thing when you're ready.",
          )
        else
          _buildTaskCard(nowTask),
        const SizedBox(height: AppSpacing.md),
        _SectionHeader(
          title: 'Next',
          count: nextTasks.length,
          icon: Icons.playlist_add_check_rounded,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (nextTasks.isEmpty)
          const _SectionEmpty(message: 'Nothing else waiting right now.')
        else
          ...nextTasks.map(_buildTaskCard),
        if (laterTasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionHeader(
            title: 'Later',
            count: laterTasks.length,
            icon: Icons.inventory_2_outlined,
            expanded: _showLater,
            onTap: () => setState(() => _showLater = !_showLater),
          ),
          if (_showLater) ...[
            const SizedBox(height: AppSpacing.xs),
            ...laterTasks.map(_buildTaskCard),
          ] else
            _SectionEmpty(
              message: '${laterTasks.length} tasks tucked away.',
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        _SectionHeader(
          title: 'Done',
          count: completed.length,
          icon: Icons.check_circle_outline_rounded,
          expanded: _showCompleted,
          onTap: () => setState(() => _showCompleted = !_showCompleted),
        ),
        if (_showCompleted) ...[
          const SizedBox(height: AppSpacing.xs),
          if (completed.isEmpty)
            const _SectionEmpty(
              message: 'Completed tasks will show here.',
            )
          else
            ...completed.map(_buildTaskCard),
        ],
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    final expanded = _expandedTaskIds.contains(task.id);
    final busy = widget.taskState.isTaskBusy(task.id);
    final settingsState = context.watch<SettingsState>();
    final reminderState = context.watch<TaskReminderState>();
    final reminder = reminderState.reminderFor(task.id);
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final statusColor = task.isCompleted
        ? semantic.success
        : _dayDifference(task.dueDate) < 0
            ? semantic.danger
            : _dayDifference(task.dueDate) <= 1
                ? semantic.warning
                : colorScheme.primary;
    final compactActions = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final useActionMenu =
        compactActions || MediaQuery.sizeOf(context).width < 430;

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
                                if (task.friction != null)
                                  _StatusBadge(
                                    label: task.friction!.label,
                                    color: colorScheme.secondary,
                                    icon: Icons.psychology_alt_outlined,
                                  ),
                                if (reminder != null)
                                  _StatusBadge(
                                    label: 'Nudge set',
                                    color: colorScheme.secondary,
                                    icon: Icons.notifications_active_outlined,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (useActionMenu)
                    PopupMenuButton<String>(
                      tooltip: 'Task actions for ${task.title}',
                      icon: const Icon(Icons.more_horiz_rounded),
                      enabled: !busy,
                      onSelected: (value) {
                        if (value == 'startTiny') _startTinyFocus(task);
                        if (value == 'stuck') {
                          showTaskSupportSheet(context: context, task: task);
                        }
                        if (value == 'remindLater') {
                          _remindTask(
                            task,
                            tomorrow: false,
                            settings: settingsState,
                            reminders: reminderState,
                          );
                        }
                        if (value == 'remindTomorrow') {
                          _remindTask(
                            task,
                            tomorrow: true,
                            settings: settingsState,
                            reminders: reminderState,
                          );
                        }
                        if (value == 'cancelReminder') {
                          _cancelReminder(task, reminderState);
                        }
                        if (value == 'edit') _showEditTask(task);
                        if (value == 'delete') _deleteWithUndo(task);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'startTiny',
                          child: ListTile(
                            leading: Icon(Icons.bolt_rounded),
                            title: Text('Start 2 min'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'stuck',
                          child: ListTile(
                            leading: Icon(Icons.psychology_alt_outlined),
                            title: Text("I'm stuck"),
                          ),
                        ),
                        if (!task.isCompleted)
                          const PopupMenuItem(
                            value: 'remindLater',
                            child: ListTile(
                              leading: Icon(Icons.notifications_none_rounded),
                              title: Text('Remind later'),
                            ),
                          ),
                        if (!task.isCompleted)
                          const PopupMenuItem(
                            value: 'remindTomorrow',
                            child: ListTile(
                              leading: Icon(Icons.event_available_outlined),
                              title: Text('Remind tomorrow'),
                            ),
                          ),
                        if (reminder != null)
                          const PopupMenuItem(
                            value: 'cancelReminder',
                            child: ListTile(
                              leading: Icon(Icons.notifications_off_outlined),
                              title: Text('Cancel nudge'),
                            ),
                          ),
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
                      key: ValueKey('start-tiny-${task.id}'),
                      tooltip: 'Start 2-minute focus for ${task.title}',
                      onPressed: busy ? null : () => _startTinyFocus(task),
                      icon: const Icon(Icons.bolt_rounded),
                      iconSize: 22,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      tooltip: "I'm stuck on ${task.title}",
                      onPressed: busy
                          ? null
                          : () => showTaskSupportSheet(
                                context: context,
                                task: task,
                              ),
                      icon: const Icon(Icons.psychology_alt_outlined),
                      iconSize: 22,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      tooltip: reminder == null
                          ? 'Remind later for ${task.title}'
                          : 'Cancel nudge for ${task.title}',
                      onPressed: busy
                          ? null
                          : () {
                              if (reminder == null) {
                                _remindTask(
                                  task,
                                  tomorrow: false,
                                  settings: settingsState,
                                  reminders: reminderState,
                                );
                              } else {
                                _cancelReminder(task, reminderState);
                              }
                            },
                      icon: Icon(
                        reminder == null
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_active_outlined,
                      ),
                      iconSize: 22,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      tooltip: 'Edit ${task.title}',
                      onPressed: busy ? null : () => _showEditTask(task),
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 22,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      tooltip: 'Delete ${task.title}',
                      onPressed: busy ? null : () => _deleteWithUndo(task),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: semantic.danger,
                      ),
                      iconSize: 22,
                      visualDensity: VisualDensity.compact,
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
                    iconSize: 22,
                    visualDensity: VisualDensity.compact,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
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
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor:
                      colorScheme.onSurface.withOpacity(0.12),
                  disabledForegroundColor:
                      colorScheme.onSurface.withOpacity(0.38),
                  minimumSize: const Size(44, 44),
                  fixedSize: const Size(44, 44),
                ),
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

  void _startTinyFocus(Task task) {
    final started = context.read<TimerState>().startQuickFocus(2);
    _message(started ? '2 minute focus started' : 'Timer already running');
  }

  Future<void> _remindTask(
    Task task, {
    required bool tomorrow,
    required SettingsState settings,
    required TaskReminderState reminders,
  }) async {
    if (!settings.taskRemindersEnabled) {
      _message('Turn on Task nudges in Settings first.');
      return;
    }

    final tinyStep = widget.taskState.tinyStepSuggestionFor(task);
    final scheduled = tomorrow
        ? await reminders.remindTomorrow(
            task,
            tinyStep: tinyStep,
            style: settings.taskReminderStyle,
          )
        : await reminders.remindLater(
            task,
            tinyStep: tinyStep,
            style: settings.taskReminderStyle,
          );

    if (!mounted) return;
    _message(
      scheduled
          ? tomorrow
              ? 'Reminder set for tomorrow'
              : 'Reminder set for later'
          : reminders.lastError ?? 'Could not set reminder.',
    );
  }

  Future<void> _cancelReminder(
    Task task,
    TaskReminderState reminders,
  ) async {
    try {
      await reminders.cancelReminder(task.id);
      if (mounted) _message('Reminder canceled');
    } catch (_) {
      if (mounted) _message('Could not cancel that reminder.');
    }
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
    showDialog<void>(
      context: context,
      builder: (_) => _EditTaskDialog(
        task: task,
        onSave: (title, dueDate) {
          return _run(
            () => widget.taskState.editTask(task.id, title, dueDate),
          );
        },
      ),
    );
  }

  void _showEditSubtask(Task task, Subtask subtask) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditSubtaskDialog(
        subtask: subtask,
        onSave: (title) {
          return _run(
            () => widget.taskState.editSubtask(task.id, subtask.id, title),
          );
        },
      ),
    );
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

class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({
    required this.task,
    required this.onSave,
  });

  final Task task;
  final Future<bool> Function(String title, DateTime dueDate) onSave;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final TextEditingController _controller;
  late DateTime _selectedDate;
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.title);
    _selectedDate = widget.task.dueDate;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = 'Task name cannot be blank');
      return;
    }

    setState(() {
      _errorText = null;
      _saving = true;
    });
    final success = await widget.onSave(title, _selectedDate);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_saving,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Task name',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving' : 'Save'),
        ),
      ],
    );
  }
}

class _EditSubtaskDialog extends StatefulWidget {
  const _EditSubtaskDialog({
    required this.subtask,
    required this.onSave,
  });

  final Subtask subtask;
  final Future<bool> Function(String title) onSave;

  @override
  State<_EditSubtaskDialog> createState() => _EditSubtaskDialogState();
}

class _EditSubtaskDialogState extends State<_EditSubtaskDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.subtask.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = 'Step name cannot be blank');
      return;
    }

    setState(() {
      _errorText = null;
      _saving = true;
    });
    final success = await widget.onSave(title);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit step'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        enabled: !_saving,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Step name',
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving' : 'Save'),
        ),
      ],
    );
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.xs),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Delete ${subtask.title}',
              onPressed: enabled ? onDelete : null,
              icon: const Icon(Icons.close_rounded, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
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
