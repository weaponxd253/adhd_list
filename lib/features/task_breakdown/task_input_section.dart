import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_state.dart';

class TaskInputSection extends StatefulWidget {
  final TextEditingController taskController;
  const TaskInputSection({super.key, required this.taskController});

  @override
  _TaskInputSectionState createState() => _TaskInputSectionState();
}

class _TaskInputSectionState extends State<TaskInputSection> {
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Theme.of(context).cardTheme.color,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _clearDate() => setState(() => _selectedDate = null);

  Future<void> _submit() async {
    final title = widget.taskController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task name')),
      );
      return;
    }
    // Due date is optional — default to 30 days out if not set
    final due = _selectedDate ?? DateTime.now().add(const Duration(days: 30));
    try {
      await Provider.of<TaskState>(context, listen: false).addTask(title, due);
      if (!mounted) return;
      widget.taskController.clear();
      setState(() => _selectedDate = null);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the task. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE4E4F0),
          ),
        ),
      ),
      child: Column(
        children: [
          // Task name input
          TextField(
            controller: widget.taskController,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'What do you need to do?',
              prefixIcon: Icon(Icons.edit_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),

          // Date chip + Add button row
          Row(
            children: [
              // Date selector — optional
              Expanded(
                child: _selectedDate == null
                    ? OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon:
                            const Icon(Icons.calendar_today_outlined, size: 16),
                        label: const Text('Due date (optional)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF2D2D44)
                                : const Color(0xFFE4E4F0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      )
                    : GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: cs.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 14, color: cs.primary),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(_selectedDate!),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _clearDate,
                                child: Icon(Icons.close_rounded,
                                    size: 14, color: cs.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),

              // Add button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, size: 18),
                    SizedBox(width: 4),
                    Text('Add'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    if (_isSameDay(date, today)) return 'Today';
    if (_isSameDay(date, tomorrow)) return 'Tomorrow';
    final diff = date.difference(today).inDays;
    if (diff < 7)
      return '${[
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun'
      ][date.weekday - 1]}';
    return '${date.day}/${date.month}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
