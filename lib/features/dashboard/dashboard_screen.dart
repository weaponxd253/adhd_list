// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/mood_state.dart';
import '../../providers/settings_state.dart';
import '../../providers/task_state.dart';
import '../../providers/timer_state.dart';
import '../../models/task.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, context.watch<SettingsState>()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Consumer<TaskState>(
            builder: (_, state, __) => _FocusNowCard(taskState: state),
          ),
          const SizedBox(height: 16),
          Consumer<TaskState>(
            builder: (_, state, __) => _StatsRow(taskState: state),
          ),
          const SizedBox(height: 16),
          Consumer<MoodState>(
            builder: (_, state, __) => _MoodCard(moodState: state),
          ),
          const SizedBox(height: 16),
          Consumer<TimerState>(
            builder: (_, state, __) => _TimerCard(timerState: state),
          ),
          const SizedBox(height: 16),
          Consumer<TaskState>(
            builder: (_, state, __) => _UpcomingSection(taskState: state),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SettingsState settings,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
          ),
          const Text('FocusFlow',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            settings.themeMode == ThemeMode.light
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
          ),
          onPressed: settings.toggleTheme,
          tooltip: 'Toggle theme',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) => _handleMenu(context, value),
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'clear_tasks', child: Text('Clear task history')),
            const PopupMenuItem(
                value: 'clear_moods', child: Text('Clear mood history')),
          ],
        ),
      ],
    );
  }

  void _handleMenu(
    BuildContext context,
    String value,
  ) {
    final label = value == 'clear_tasks' ? 'task' : 'mood';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear $label history?'),
        content: Text(
            'This will permanently delete all $label data. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (value == 'clear_tasks') {
                  await context.read<TaskState>().clearTaskHistory();
                } else {
                  await context.read<MoodState>().clearMoodHistory();
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${label[0].toUpperCase()}${label.substring(1)} history cleared',
                    ),
                  ),
                );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not clear $label history. Try again.',
                    ),
                  ),
                );
              }
            },
            child: Text('Clear',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Focus Now card ───────────────────────────────────────────────────────────

class _FocusNowCard extends StatelessWidget {
  final TaskState taskState;
  const _FocusNowCard({required this.taskState});

  @override
  Widget build(BuildContext context) {
    final nextTask =
        taskState.upcomingTasks.isEmpty ? null : taskState.upcomingTasks.first;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.18)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: nextTask == null
          ? _emptyState(context)
          : _taskState(context, nextTask, cs),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('🎯', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('All caught up!',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70)),
        ]),
        const SizedBox(height: 6),
        const Text(
          'No pending tasks. Add a new one to get started.',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ],
    );
  }

  Widget _taskState(BuildContext context, Task task, ColorScheme cs) {
    final dueStr = DateFormat.MMMd().format(task.dueDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('🎯', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            'Focus now',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          task.title,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.calendar_today_outlined,
              color: Colors.white60, size: 13),
          const SizedBox(width: 4),
          Text(dueStr,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(width: 12),
            const Icon(Icons.checklist_rounded,
                color: Colors.white60, size: 13),
            const SizedBox(width: 4),
            Text(
              '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length} steps',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ]),
      ],
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final TaskState taskState;
  const _StatsRow({required this.taskState});

  @override
  Widget build(BuildContext context) {
    final total = taskState.totalTasks;
    final completed = taskState.completedTasks;
    final progress = total == 0 ? 0.0 : completed / total;

    return Column(
      children: [
        Row(
          children: [
            _StatPill(
                label: 'Total',
                value: '$total',
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            _StatPill(
                label: 'Done',
                value: '$completed',
                color: const Color(0xFF16A34A)),
            const SizedBox(width: 8),
            _StatPill(
                label: 'Remaining',
                value: '${taskState.pendingTasks}',
                color: const Color(0xFFD97706)),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  width: progress * c.maxWidth,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        const Color(0xFF16A34A),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            total == 0
                ? 'No tasks yet'
                : '${(progress * 100).round()}% complete',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

// ─── Mood card ────────────────────────────────────────────────────────────────

class _MoodCard extends StatelessWidget {
  final MoodState moodState;
  const _MoodCard({required this.moodState});

  @override
  Widget build(BuildContext context) {
    final hasMood = moodState.selectedMood.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              hasMood ? moodState.selectedMoodEmoji : '😶',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasMood ? moodState.selectedMood : 'How are you feeling?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (hasMood)
                    Text(
                      moodState.moodMessage,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// ─── Compact timer card ───────────────────────────────────────────────────────

class _TimerCard extends StatelessWidget {
  final TimerState timerState;
  const _TimerCard({required this.timerState});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_rounded, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timerState.timerDisplay,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: cs.primary)),
                  Text(timerState.currentMode,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            _TimerButton(
              label: timerState.isTimerRunning ? 'Pause' : 'Start',
              onTap: timerState.isTimerRunning
                  ? timerState.pauseTimer
                  : timerState.startTimer,
              primary: !timerState.isTimerRunning,
            ),
            const SizedBox(width: 8),
            _TimerButton(
              label: 'Reset',
              onTap: timerState.resetTimer,
              primary: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _TimerButton(
      {required this.label, required this.onTap, required this.primary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: primary ? cs.primary : cs.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primary ? Colors.white : cs.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Upcoming tasks ───────────────────────────────────────────────────────────

class _UpcomingSection extends StatefulWidget {
  final TaskState taskState;
  const _UpcomingSection({required this.taskState});
  @override
  State<_UpcomingSection> createState() => _UpcomingSectionState();
}

class _UpcomingSectionState extends State<_UpcomingSection> {
  bool _expanded = true;

  int _calendarDayDifference(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(date).difference(today).inDays;
  }

  String _countdown(DateTime due) {
    final diff = _calendarDayDifference(due);
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'In $diff days';
  }

  Color _urgencyColor(DateTime due) {
    final diff = _calendarDayDifference(due);
    if (diff < 0) return const Color(0xFFDC2626);
    if (diff <= 1) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.taskState.upcomingTasks;
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text('Upcoming', style: Theme.of(context).textTheme.titleMedium),
              if (tasks.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Nothing coming up — enjoy the moment!',
                  style: Theme.of(context).textTheme.bodyMedium),
            )
          else
            ...tasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _UpcomingTile(
                      task: t,
                      countdown: _countdown,
                      urgencyColor: _urgencyColor),
                )),
        ],
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final Task task;
  final String Function(DateTime) countdown;
  final Color Function(DateTime) urgencyColor;
  const _UpcomingTile(
      {required this.task,
      required this.countdown,
      required this.urgencyColor});

  @override
  Widget build(BuildContext context) {
    final dueDate = task.dueDate;
    final color = urgencyColor(dueDate);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat.MMMd().format(dueDate)} · ${countdown(dueDate)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
