import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/task.dart';
import '../../models/subtask.dart';

class TaskListSection extends StatefulWidget {
  final List<Task> tasks;
  const TaskListSection({super.key, required this.tasks});

  @override
  _TaskListSectionState createState() => _TaskListSectionState();
}

class _TaskListSectionState extends State<TaskListSection> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final Set<int> _expanded = {};

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    for (final f in _focusNodes.values) f.dispose();
    super.dispose();
  }

  TextEditingController _controller(int id) =>
      _controllers.putIfAbsent(id, () => TextEditingController());
  FocusNode _focusNode(int id) =>
      _focusNodes.putIfAbsent(id, () => FocusNode());

  Color _accentColor(Task task) {
    if (task.isCompleted) return const Color(0xFF16A34A);
    if (task.dueDate == null) return const Color(0xFF6366F1);
    final diff = task.dueDate!.difference(DateTime.now()).inDays;
    if (diff < 0)  return const Color(0xFFDC2626); // overdue
    if (diff <= 1) return const Color(0xFFD97706); // due soon
    return const Color(0xFF6366F1);                // upcoming
  }

  String _dueBadge(Task task) {
    if (task.dueDate == null) return '';
    final diff = task.dueDate!.difference(DateTime.now()).inDays;
    if (task.isCompleted) return 'Done';
    if (diff < 0)  return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${task.dueDate!.day}/${task.dueDate!.month}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.checklist_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15)),
              const SizedBox(height: 16),
              Text('No tasks yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4))),
              const SizedBox(height: 4),
              Text('Add one above to get started',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: widget.tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        final isExpanded = _expanded.contains(task.id);
        final accent = _accentColor(task);
        final badge = _dueBadge(task);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ── Task row ──────────────────────────────────────────
              InkWell(
                onTap: () => setState(() {
                  if (isExpanded) _expanded.remove(task.id);
                  else _expanded.add(task.id);
                }),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left accent bar
                      Container(width: 4, color: accent),

                      // Checkbox
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: task.isCompleted,
                            onChanged: (_) => Provider.of<AppState>(context, listen: false)
                                .toggleTaskCompletion(index),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),

                      // Title + badge
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                task.title,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                                      : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (badge.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accent.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        badge,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (task.subtasks.isNotEmpty)
                                    Text(
                                      '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length} steps',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Actions + expand
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () => _showEditDialog(context, task),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            color: const Color(0xFFDC2626),
                            onPressed: () => _confirmDelete(context, task, index),
                            visualDensity: VisualDensity.compact,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Expanded subtasks ─────────────────────────────────
              if (isExpanded) ...[
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerTheme.color,
                ),
                ...task.subtasks.asMap().entries.map((e) {
                  final si = e.key;
                  final sub = e.value;
                  return _SubtaskTile(
                    subtask: sub,
                    onToggle: () => Provider.of<AppState>(context, listen: false)
                        .toggleSubtaskCompletion(index, si),
                    onEdit: () => _showEditSubtaskDialog(context, index, si, sub.title),
                    onDelete: () => Provider.of<AppState>(context, listen: false)
                        .deleteSubtask(index, si),
                  );
                }),

                // Add subtask input
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _controller(task.id),
                          focusNode: _focusNode(task.id),
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Add a step...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.35),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          onSubmitted: (text) => _addSubtask(context, task, index, text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _addSubtask(
                              context, task, index, _controller(task.id).text);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _addSubtask(BuildContext context, Task task, int taskIndex, String text) {
    final t = text.trim();
    if (t.isNotEmpty) {
      Provider.of<AppState>(context, listen: false).addSubtask(taskIndex, t);
      _controller(task.id).clear();
      _focusNode(task.id).unfocus();
    }
  }

  void _confirmDelete(BuildContext context, Task task, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AppState>(context, listen: false).deleteTask(task.id);
              _controllers.remove(task.id)?.dispose();
              _focusNodes.remove(task.id)?.dispose();
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showEditSubtaskDialog(
      BuildContext context, int ti, int si, String current) {
    final c = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit step'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Provider.of<AppState>(context, listen: false).editSubtask(ti, si, c.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Task task) {
    final tc = TextEditingController(text: task.title);
    DateTime selected = task.dueDate ?? DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, set) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tc, autofocus: true,
                  decoration: const InputDecoration(labelText: 'Task name')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: selected,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (p != null) set(() => selected = p);
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text('${selected.day}/${selected.month}/${selected.year}'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Provider.of<AppState>(context, listen: false)
                    .editTask(task.id, tc.text, selected);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subtask tile ──────────────────────────────────────────────────────────────

class _SubtaskTile extends StatelessWidget {
  final Subtask subtask;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _SubtaskTile({
    required this.subtask,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 4),
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: subtask.isCompleted,
              onChanged: (_) => onToggle(),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                fontSize: 14,
                color: subtask.isCompleted
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.35)
                    : null,
                decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 15),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 15),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
          ),
        ],
      ),
    );
  }
}