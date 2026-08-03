import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../features/mood_tracker/mood_tracker_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../models/task.dart';
import '../../models/task_support.dart';
import '../../providers/mood_state.dart';
import '../../providers/task_state.dart';
import '../../providers/timer_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_support_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onOpenMood, this.onOpenTimer});

  final VoidCallback? onOpenMood;
  final VoidCallback? onOpenTimer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Consumer3<TaskState, MoodState, TimerState>(
        builder: (context, taskState, moodState, timerState, _) {
          final nowTask = taskState.upcomingTasks.isEmpty
              ? null
              : taskState.upcomingTasks.first;

          return ListView(
            padding: AppInsets.screenScrollPadding(
              context,
              left: AppSpacing.md,
              top: AppSpacing.xs,
              right: AppSpacing.md,
            ),
            children: [
              _NowCard(task: nowTask, onOpenTimer: onOpenTimer),
              const SizedBox(height: AppSpacing.md),
              _TodayStrip(taskState: taskState, timerState: timerState),
              const SizedBox(height: AppSpacing.md),
              _MoodCard(moodState: moodState, onOpenMood: onOpenMood),
              const SizedBox(height: AppSpacing.md),
              _TimerSummaryCard(timerState: timerState, task: nowTask),
              const SizedBox(height: AppSpacing.md),
              _UpcomingPreview(taskState: taskState, nowTask: nowTask),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 12,
                ),
          ),
          const Text(
            'FocusFlow',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

class _NowCard extends StatelessWidget {
  const _NowCard({required this.task, required this.onOpenTimer});

  final Task? task;
  final VoidCallback? onOpenTimer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final task = this.task;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.16)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: task == null ? _emptyState(context) : _taskState(context, task),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Now',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'All caught up',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        const Text(
          'Add a task when you are ready for the next tiny move.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _taskState(BuildContext context, Task task) {
    final dueStr = DateFormat.MMMd().format(task.dueDate);
    final completedSteps = task.subtasks.where((s) => s.isCompleted).length;
    final totalSteps = task.subtasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_rounded, color: Colors.white70, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Now',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          task.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _NowMeta(icon: Icons.calendar_today_outlined, label: dueStr),
            _NowMeta(
              icon: Icons.checklist_rounded,
              label: '$completedSteps/$totalSteps steps',
            ),
            if (task.friction != null)
              _NowMeta(
                icon: Icons.psychology_alt_outlined,
                label: task.friction!.label,
              ),
          ],
        ),
        if (task.tinyNextStep != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            task.tinyNextStep!,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('dashboard-start-5'),
          onPressed: () => _startFocus(context, 5),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start 5 min'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _NowSecondaryButton(
                key: const Key('dashboard-stuck'),
                label: "I'm stuck",
                icon: Icons.psychology_alt_outlined,
                onTap: () => showTaskSupportSheet(context: context, task: task),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _NowSecondaryButton(
                key: const Key('dashboard-tiny-step'),
                label: 'Tiny step',
                icon: Icons.call_split_rounded,
                onTap: () => _addTinyStep(context, task),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addTinyStep(BuildContext context, Task task) async {
    final step = task.tinyNextStep ??
        'Open "${task.title}" and do one visible next step.';
    try {
      await context.read<TaskState>().addSubtask(task.id, step);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Tiny step added')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add the tiny step.')),
      );
    }
  }

  void _startFocus(BuildContext context, int minutes) {
    context.read<TimerState>().startQuickFocus(minutes);
    onOpenTimer?.call();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$minutes minute focus started')),
      );
  }
}

class _NowMeta extends StatelessWidget {
  const _NowMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NowSecondaryButton extends StatelessWidget {
  const _NowSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        backgroundColor: Colors.white.withValues(alpha: 0.10),
      ),
    );
  }
}

class _TodayStrip extends StatelessWidget {
  const _TodayStrip({
    required this.taskState,
    required this.timerState,
  });

  final TaskState taskState;
  final TimerState timerState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _TodayMetric(
              value: '${timerState.focusMinutesToday}m',
              label: 'focus',
            ),
            _TodayMetric(
              value: '${timerState.completedSessionsToday}',
              label: 'started',
            ),
            _TodayMetric(
              value: '${taskState.completedTasks}',
              label: 'done',
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayMetric extends StatelessWidget {
  const _TodayMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: cs.outlineVariant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.moodState, required this.onOpenMood});

  final MoodState moodState;
  final VoidCallback? onOpenMood;

  @override
  Widget build(BuildContext context) {
    final hasMood = moodState.selectedMood.isNotEmpty;
    return Card(
      child: InkWell(
        key: const Key('dashboard-mood-card'),
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onOpenMood ??
            () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
                ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text(
                hasMood ? moodState.selectedMoodEmoji : ':|',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: AppSpacing.sm),
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
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerSummaryCard extends StatelessWidget {
  const _TimerSummaryCard({required this.timerState, required this.task});

  final TimerState timerState;
  final Task? task;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final description = timerState.isTimerRunning
        ? '${timerState.currentMode} in progress'
        : task == null
            ? 'Ready for a focus session'
            : 'Ready to focus on ${task!.title}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                constraints.maxWidth < 340;
            final controls = [
              _TimerButton(
                label: timerState.isTimerRunning ? 'Pause' : 'Start',
                onTap: timerState.isTimerRunning
                    ? timerState.pauseTimer
                    : timerState.startTimer,
                primary: !timerState.isTimerRunning,
              ),
              _TimerButton(
                label: 'Reset',
                onTap: timerState.resetTimer,
                primary: false,
              ),
            ];

            final summary = Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.timer_rounded, color: cs.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timerState.timerDisplay,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summary,
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: controls,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: summary),
                const SizedBox(width: AppSpacing.sm),
                ...controls.expand(
                  (button) => [
                    button,
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  const _TimerButton({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semanticLabel = label == 'Reset' ? 'Reset timer' : '$label timer';

    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: primary ? cs.primary : cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.control),
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
        ),
      ),
    );
  }
}

class _UpcomingPreview extends StatefulWidget {
  const _UpcomingPreview({required this.taskState, required this.nowTask});

  final TaskState taskState;
  final Task? nowTask;

  @override
  State<_UpcomingPreview> createState() => _UpcomingPreviewState();
}

class _UpcomingPreviewState extends State<_UpcomingPreview> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final tasks = widget.taskState.upcomingTasks
        .where((task) => task.id != widget.nowTask?.id)
        .take(3)
        .toList();

    return Column(
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label: 'Upcoming tasks, ${tasks.length}',
          child: InkWell(
            key: const Key('dashboard-upcoming-toggle'),
            borderRadius: BorderRadius.circular(AppRadii.control),
            onTap: () => setState(() => _expanded = !_expanded),
            child: SizedBox(
              height: AppSizes.minimumTouchTarget,
              child: Row(
                children: [
                  Text(
                    'Upcoming',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (tasks.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _CountPill(count: tasks.length),
                  ],
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Nothing else waiting right now.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _UpcomingTile(task: task),
              ),
            ),
        ],
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(task.dueDate);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${DateFormat.MMMd().format(task.dueDate)} - ${_countdown(task.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calendarDayDifference(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(date).difference(today).inDays;
  }

  String _countdown(DateTime due) {
    final diff = _calendarDayDifference(due);
    if (diff < 0) return 'overdue';
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    return 'in $diff days';
  }

  Color _urgencyColor(DateTime due) {
    final diff = _calendarDayDifference(due);
    if (diff < 0) return const Color(0xFFDC2626);
    if (diff <= 1) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }
}
