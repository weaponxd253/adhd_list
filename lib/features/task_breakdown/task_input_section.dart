import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_state.dart';
import '../../providers/settings_state.dart';
import '../../theme/app_theme.dart';

class TaskInputSection extends StatefulWidget {
  const TaskInputSection({super.key, required this.taskController});

  final TextEditingController taskController;

  @override
  State<TaskInputSection> createState() => _TaskInputSectionState();
}

class _TaskInputSectionState extends State<TaskInputSection> {
  DateTime? _selectedDate;
  String? _errorText;

  Future<void> _pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(2100),
      helpText: 'Choose a task due date',
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final title = widget.taskController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = 'Enter a task name');
      return;
    }

    setState(() => _errorText = null);
    final defaultOffsetDays =
        context.read<SettingsState>().defaultDueDateOffsetDays;
    final dueDate =
        _selectedDate ?? DateTime.now().add(Duration(days: defaultOffsetDays));
    try {
      await context.read<TaskState>().addTask(title, dueDate);
      if (!mounted) return;
      widget.taskController.clear();
      setState(() => _selectedDate = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the task. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TaskState>();
    final dueLabel =
        _selectedDate == null ? 'Due date' : _formatDate(_selectedDate!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('task-name-field'),
                controller: widget.taskController,
                enabled: !state.isCreating,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                onSubmitted: (_) => state.isCreating ? null : _submit(),
                decoration: InputDecoration(
                  hintText: 'What needs doing?',
                  errorText: _errorText,
                  prefixIcon: const Icon(Icons.add_task_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackActions =
                      MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                          constraints.maxWidth < 320;
                  final dateButton = OutlinedButton.icon(
                    key: const Key('task-due-date-button'),
                    onPressed: state.isCreating ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(dueLabel, overflow: TextOverflow.ellipsis),
                  );
                  final addButton = ElevatedButton.icon(
                    key: const Key('add-task-button'),
                    onPressed: state.isCreating ? null : _submit,
                    icon: state.isCreating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded, size: 20),
                    label: Text(state.isCreating ? 'Adding' : 'Add task'),
                  );

                  if (stackActions) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: dateButton),
                            if (_selectedDate != null)
                              IconButton(
                                tooltip: 'Clear due date',
                                onPressed: state.isCreating
                                    ? null
                                    : () => setState(
                                          () => _selectedDate = null,
                                        ),
                                icon: const Icon(Icons.close_rounded),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        addButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: dateButton),
                      if (_selectedDate != null)
                        IconButton(
                          tooltip: 'Clear due date',
                          onPressed: state.isCreating
                              ? null
                              : () => setState(() => _selectedDate = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      const SizedBox(width: AppSpacing.xs),
                      addButton,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(date);
    final difference = selected.difference(today).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    return '${date.month}/${date.day}/${date.year}';
  }
}
