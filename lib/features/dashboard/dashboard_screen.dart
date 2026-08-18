import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../features/mood_tracker/mood_tracker_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../models/daily_plan.dart';
import '../../models/task.dart';
import '../../models/task_reminder.dart';
import '../../models/task_support.dart';
import '../../providers/mood_state.dart';
import '../../providers/task_state.dart';
import '../../providers/settings_state.dart';
import '../../providers/task_reminder_state.dart';
import '../../providers/timer_state.dart';
import '../../services/daily_plan_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_support_sheet.dart';
import '../../widgets/timer_completion_prompt.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onOpenMood, this.onOpenTimer});

  final VoidCallback? onOpenMood;
  final VoidCallback? onOpenTimer;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DailyPlanService _dailyPlanService = DailyPlanService();
  DailyCapacity _capacity = DailyCapacity.medium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Consumer5<TaskState, MoodState, TimerState, SettingsState,
          TaskReminderState>(
        builder: (
          context,
          taskState,
          moodState,
          timerState,
          settingsState,
          reminderState,
          _,
        ) {
          final dailyPlan = _dailyPlanService.build(
            tasks: taskState.tasks,
            timerState: timerState,
            capacity: _capacity,
            mood: moodState.selectedMood,
          );
          final nowTask = dailyPlan.nowTask ?? taskState.nowTask;
          final waitingTask = taskState.waitingTask;

          return ListView(
            padding: AppInsets.screenScrollPadding(
              context,
              left: AppSpacing.md,
              top: AppSpacing.xs,
              right: AppSpacing.md,
            ),
            children: [
              _NowCard(
                taskState: taskState,
                moodState: moodState,
                timerState: timerState,
                task: nowTask,
                insight:
                    nowTask == null ? null : dailyPlan.insightFor(nowTask.id),
                onOpenTimer: widget.onOpenTimer,
              ),
              const SizedBox(height: AppSpacing.md),
              _TodayStrip(
                taskState: taskState,
                timerState: timerState,
                moodState: moodState,
              ),
              const SizedBox(height: AppSpacing.md),
              _NextPreview(
                timerState: timerState,
                dailyPlan: dailyPlan,
                onOpenTimer: widget.onOpenTimer,
              ),
              if (waitingTask != null) ...[
                const SizedBox(height: AppSpacing.md),
                _WaitingTaskCard(
                  taskState: taskState,
                  timerState: timerState,
                  reminderState: reminderState,
                  remindersEnabled: settingsState.taskRemindersEnabled,
                  reminderStyle: settingsState.taskReminderStyle,
                  task: waitingTask,
                  onOpenTimer: widget.onOpenTimer,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _DailyResetCard(
                moodState: moodState,
                timerState: timerState,
                capacity: _capacity,
                onCapacityChanged: (value) => setState(() {
                  _capacity = value;
                }),
                onOpenMood: widget.onOpenMood,
                onOpenTimer: widget.onOpenTimer,
              ),
              const SizedBox(height: AppSpacing.md),
              _MoodCard(moodState: moodState, onOpenMood: widget.onOpenMood),
              const SizedBox(height: AppSpacing.md),
              _DailyReviewCard(
                taskState: taskState,
                timerState: timerState,
                settingsState: settingsState,
                reminderState: reminderState,
              ),
              const SizedBox(height: AppSpacing.md),
              _TimerSummaryCard(timerState: timerState, task: nowTask),
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
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
  const _NowCard({
    required this.taskState,
    required this.moodState,
    required this.timerState,
    required this.task,
    required this.insight,
    required this.onOpenTimer,
  });

  final TaskState taskState;
  final MoodState moodState;
  final TimerState timerState;
  final Task? task;
  final DailyPlanTaskInsight? insight;
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
        child: task == null
            ? _emptyState(context)
<<<<<<< HEAD
            : _taskState(context, task, taskState, moodState, timerState),
=======
            : _taskState(
                context,
                task,
                taskState,
                moodState,
                timerState,
                insight,
              ),
>>>>>>> 116293643c717f05e5b4aafac370a2efdd93a2e1
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
          'Nothing urgent',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        const Text(
          "Pick one small thing when you're ready.",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _taskState(
    BuildContext context,
    Task task,
    TaskState taskState,
    MoodState moodState,
    TimerState timerState,
<<<<<<< HEAD
=======
    DailyPlanTaskInsight? insight,
>>>>>>> 116293643c717f05e5b4aafac370a2efdd93a2e1
  ) {
    final dueStr = DateFormat.MMMd().format(task.dueDate);
    final completedSteps = task.subtasks.where((s) => s.isCompleted).length;
    final totalSteps = task.subtasks.length;
    final tinyStep = taskState.tinyStepSuggestionFor(task);
<<<<<<< HEAD
    final focusMinutes = timerState.focusMinutesForTask(task.id);
=======
    final planLine = _nowPlanLine(insight, moodState);
>>>>>>> 116293643c717f05e5b4aafac370a2efdd93a2e1

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
            if (focusMinutes > 0)
              _NowMeta(
                icon: Icons.timer_outlined,
                label: '${focusMinutes}m focus',
              ),
            if (task.friction != null)
              _NowMeta(
                icon: Icons.psychology_alt_outlined,
                label: task.friction!.label,
                tooltip: task.friction == TaskFriction.tooBig
                    ? 'Break down ${task.title}'
                    : null,
                onTap: task.friction == TaskFriction.tooBig
                    ? () => showTaskSupportSheet(context: context, task: task)
                    : null,
              ),
            if (insight != null)
              _NowMeta(
                icon: _planReasonIcon(insight),
                label: insight.reason,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          planLine,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          tinyStep,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.md),
        _primaryFocusControls(context, task, timerState),
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

  String _nowPlanLine(DailyPlanTaskInsight? insight, MoodState moodState) {
    if (moodState.recommendsRecoveryMode) return moodState.nowTaskGuidance;
    return insight?.detail ?? moodState.nowTaskGuidance;
  }

  IconData _planReasonIcon(DailyPlanTaskInsight insight) {
    switch (insight.action) {
      case DailyPlanAction.resume:
        return Icons.history_rounded;
      case DailyPlanAction.shrinkFirst:
        return Icons.call_split_rounded;
      case DailyPlanAction.startTiny:
        return Icons.bolt_rounded;
      case DailyPlanAction.startFocus:
        return Icons.flag_outlined;
      case DailyPlanAction.moveLater:
        return Icons.inventory_2_outlined;
    }
  }

  Widget _primaryFocusControls(
    BuildContext context,
    Task task,
    TimerState timerState,
  ) {
    if (timerState.isActiveForTask(task.id)) {
      return _NowActiveFocusControls(
        timerState: timerState,
        task: task,
        onEnd: () => _endFocusNow(context),
      );
    }

    if (timerState.isActiveFocusSession) {
      return _NowOtherFocusControls(
        timerState: timerState,
        onOpenTimer: onOpenTimer,
      );
    }

    final style = FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Theme.of(context).colorScheme.primary,
    );
    final buttons = [
      FilledButton.icon(
        key: const Key('dashboard-start-tiny'),
        onPressed: () => _startFocus(context, task, 2),
        icon: const Icon(Icons.bolt_rounded),
        label: const Text('Start 2 min'),
        style: style,
      ),
      FilledButton.icon(
        key: const Key('dashboard-start-5'),
        onPressed: () => _startFocus(context, task, 5),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start 5 min'),
        style: style,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 340 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buttons[0],
              const SizedBox(height: AppSpacing.xs),
              buttons[1],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: buttons[0]),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: buttons[1]),
          ],
        );
      },
    );
  }

  Future<void> _addTinyStep(BuildContext context, Task task) async {
    try {
      final added = await context.read<TaskState>().addTinyStep(task.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              added ? 'Tiny step added' : 'Tiny step is already there',
            ),
          ),
        );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add the tiny step.')),
      );
    }
  }

  void _startFocus(BuildContext context, Task task, int minutes) {
    final started = context.read<TimerState>().startTargetFocus(
          minutes: minutes,
          targetType: TimerState.targetTypeTask,
          taskId: task.id,
          title: task.title,
        );
    if (started) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('A focus session is already running.')),
      );
  }

  void _endFocusNow(BuildContext context) {
    final ended = context.read<TimerState>().endCurrentSessionEarly();
    if (!ended) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No active focus session to end.')),
        );
      return;
    }

    showPendingTimerCompletionPrompt(context);
  }
}

class _NowActiveFocusControls extends StatelessWidget {
  const _NowActiveFocusControls({
    required this.timerState,
    required this.task,
    required this.onEnd,
  });

  final TimerState timerState;
  final Task task;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final targetTitle = timerState.activeTargetTitle;
    final detail =
        targetTitle == null || targetTitle == task.title ? null : targetTitle;
    final status = timerState.isTimerRunning ? 'In progress' : 'Paused';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$status · ${timerState.timerDisplay} left',
                    key: const Key('dashboard-active-focus'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            OutlinedButton.icon(
              key: const Key('dashboard-end-active-focus'),
              onPressed: onEnd,
              icon: const Icon(Icons.stop_circle_outlined, size: 18),
              label: const Text('End now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowOtherFocusControls extends StatelessWidget {
  const _NowOtherFocusControls({
    required this.timerState,
    required this.onOpenTimer,
  });

  final TimerState timerState;
  final VoidCallback? onOpenTimer;

  @override
  Widget build(BuildContext context) {
    final title = timerState.activeTargetTitle ?? 'Focus session';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Timer running · $title',
                key: const Key('dashboard-other-focus'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              key: const Key('dashboard-open-active-timer'),
              onPressed: onOpenTimer,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Timer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowMeta extends StatelessWidget {
  const _NowMeta({
    required this.icon,
    required this.label,
    this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
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
    final onTap = this.onTap;
    if (onTap == null) return content;

    return Tooltip(
      message: tooltip ?? label,
      child: Semantics(
        button: true,
        label: tooltip ?? label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: content,
          ),
        ),
      ),
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
        backgroundColor: Colors.white.withOpacity(0.10),
      ),
    );
  }
}

class _TodayStrip extends StatelessWidget {
  const _TodayStrip({
    required this.taskState,
    required this.timerState,
    required this.moodState,
  });

  final TaskState taskState;
  final TimerState timerState;
  final MoodState moodState;

  @override
  Widget build(BuildContext context) {
    final supportLine = _supportLine();

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
              label: 'sessions',
            ),
            _TodayMetric(
              value: '${taskState.completedTasksToday}',
              label: 'tasks',
            ),
            _TodayMetric(
              value:
                  '${taskState.completedSubtasks}/${taskState.totalSubtasks}',
              label: 'steps',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          supportLine,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _supportLine() {
    if (timerState.focusMinutesToday > 0) {
      return 'You protected your focus today.';
    }
    if (taskState.completedTasksToday > 0) {
      return 'You showed up and finished something.';
    }
    if (taskState.completedSubtasks > 0) {
      return 'One step is still progress.';
    }
    if (moodState.selectedMood.isNotEmpty) {
      return moodState.moodPlanSuggestion;
    }
    if (taskState.nowTask != null) {
      return 'Tomorrow already has a starting point.';
    }
    return 'One small check-in counts.';
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

enum _NudgeStyle { gentle, direct, tinyStep }

class _WaitingTaskCard extends StatefulWidget {
  const _WaitingTaskCard({
    required this.taskState,
    required this.timerState,
    required this.reminderState,
    required this.remindersEnabled,
    required this.reminderStyle,
    required this.task,
    required this.onOpenTimer,
  });

  final TaskState taskState;
  final TimerState timerState;
  final TaskReminderState reminderState;
  final bool remindersEnabled;
  final TaskReminderStyle reminderStyle;
  final Task task;
  final VoidCallback? onOpenTimer;

  @override
  State<_WaitingTaskCard> createState() => _WaitingTaskCardState();
}

class _WaitingTaskCardState extends State<_WaitingTaskCard> {
  _NudgeStyle _style = _NudgeStyle.gentle;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final task = widget.task;
    final tinyStep = widget.taskState.tinyStepSuggestionFor(task);
    final reminder = widget.reminderState.reminderFor(task.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.history_toggle_off_rounded, color: cs.secondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'This has been waiting',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              task.title,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<_NudgeStyle>(
              key: const Key('waiting-nudge-style'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _NudgeStyle.gentle,
                  label: Text('Gentle'),
                  icon: Icon(Icons.spa_outlined),
                ),
                ButtonSegment(
                  value: _NudgeStyle.direct,
                  label: Text('Direct'),
                  icon: Icon(Icons.arrow_forward_rounded),
                ),
                ButtonSegment(
                  value: _NudgeStyle.tinyStep,
                  label: Text('Tiny step'),
                  icon: Icon(Icons.call_split_rounded),
                ),
              ],
              selected: {_style},
              onSelectionChanged: (selection) {
                setState(() => _style = selection.single);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _nudgeCopy(tinyStep),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (reminder != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _ReminderStatusLine(reminder: reminder),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                FilledButton.icon(
                  key: const Key('waiting-shrink-task'),
                  onPressed: _saving ? null : _shrinkTask,
                  icon: const Icon(Icons.call_split_rounded),
                  label: const Text('Shrink it'),
                ),
                OutlinedButton.icon(
                  key: const Key('waiting-move-later'),
                  onPressed: _saving ? null : _moveToLater,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Move to Later'),
                ),
                OutlinedButton.icon(
                  key: const Key('waiting-start-tiny'),
                  onPressed: _saving ? null : _startTiny,
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text('Start 2 min'),
                ),
                OutlinedButton.icon(
                  key: const Key('waiting-remind-later'),
                  onPressed: _saving ? null : () => _scheduleReminder(false),
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: const Text('Remind later'),
                ),
                OutlinedButton.icon(
                  key: const Key('waiting-remind-tomorrow'),
                  onPressed: _saving ? null : () => _scheduleReminder(true),
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('Remind tomorrow'),
                ),
                if (reminder != null)
                  TextButton.icon(
                    key: const Key('waiting-cancel-reminder'),
                    onPressed: _saving ? null : _cancelReminder,
                    icon: const Icon(Icons.notifications_off_outlined),
                    label: const Text('Cancel nudge'),
                  ),
              ],
            ),
            if (_saving) ...[
              const SizedBox(height: AppSpacing.sm),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
    );
  }

  TaskReminderStyle get _selectedReminderStyle {
    switch (_style) {
      case _NudgeStyle.gentle:
        return TaskReminderStyle.gentle;
      case _NudgeStyle.direct:
        return TaskReminderStyle.direct;
      case _NudgeStyle.tinyStep:
        return TaskReminderStyle.tinyStep;
    }
  }

  String _nudgeCopy(String tinyStep) {
    switch (_style) {
      case _NudgeStyle.gentle:
        return 'Still worth doing. Want a 2-minute start?';
      case _NudgeStyle.direct:
        return "Open the task. That's enough to begin.";
      case _NudgeStyle.tinyStep:
        return 'Only do this next tiny step: $tinyStep';
    }
  }

  Future<void> _shrinkTask() async {
    setState(() => _saving = true);
    try {
      final added = await widget.taskState.addTinyStep(widget.task.id);
      if (!mounted) return;
      _message(added ? 'Tiny step added' : 'Tiny step is already there');
    } catch (_) {
      if (mounted) _message('Could not shrink that task.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _moveToLater() async {
    setState(() => _saving = true);
    try {
      await widget.taskState.moveTaskToLater(widget.task.id);
      if (!mounted) return;
      _message('Moved to Later');
    } catch (_) {
      if (mounted) _message('Could not move that task.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _startTiny() {
    final started = widget.timerState.startQuickFocus(2);
    widget.onOpenTimer?.call();
    _message(
      started ? '2 minute focus started' : 'A focus session is already active',
    );
  }

  Future<void> _scheduleReminder(bool tomorrow) async {
    if (!widget.remindersEnabled) {
      _message('Turn on Task nudges in Settings first.');
      return;
    }

    setState(() => _saving = true);
    try {
      final tinyStep = widget.taskState.tinyStepSuggestionFor(widget.task);
      final style = _selectedReminderStyle == widget.reminderStyle
          ? widget.reminderStyle
          : _selectedReminderStyle;
      final scheduled = tomorrow
          ? await widget.reminderState.remindTomorrow(
              widget.task,
              tinyStep: tinyStep,
              style: style,
            )
          : await widget.reminderState.remindLater(
              widget.task,
              tinyStep: tinyStep,
              style: style,
            );
      if (!mounted) return;
      _message(
        scheduled
            ? tomorrow
                ? 'Reminder set for tomorrow'
                : 'Reminder set for later'
            : widget.reminderState.lastError ?? 'Could not set reminder.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelReminder() async {
    setState(() => _saving = true);
    try {
      await widget.reminderState.cancelReminder(widget.task.id);
      if (mounted) _message('Reminder canceled');
    } catch (_) {
      if (mounted) _message('Could not cancel that reminder.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReminderStatusLine extends StatelessWidget {
  const _ReminderStatusLine({required this.reminder});

  final TaskReminder reminder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: cs.secondary.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 18,
              color: cs.secondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Nudge set ${DateFormat.MMMd().add_jm().format(reminder.scheduledAt)} (${reminder.style.label})',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyResetCard extends StatefulWidget {
  const _DailyResetCard({
    required this.moodState,
    required this.timerState,
    required this.capacity,
    required this.onCapacityChanged,
    required this.onOpenMood,
    required this.onOpenTimer,
  });

  final MoodState moodState;
  final TimerState timerState;
  final DailyCapacity capacity;
  final ValueChanged<DailyCapacity> onCapacityChanged;
  final VoidCallback? onOpenMood;
  final VoidCallback? onOpenTimer;

  @override
  State<_DailyResetCard> createState() => _DailyResetCardState();
}

class _DailyResetCardState extends State<_DailyResetCard> {
  bool _manualRecoveryMode = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final recoverySuggested = widget.capacity == DailyCapacity.low ||
        widget.moodState.recommendsRecoveryMode;
    final recoveryActive = recoverySuggested || _manualRecoveryMode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.battery_5_bar_rounded, color: cs.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Capacity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'How much capacity do you have?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<DailyCapacity>(
              key: const Key('daily-capacity-selector'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: DailyCapacity.low,
                  label: Text('Low'),
                  icon: Icon(Icons.battery_1_bar_rounded),
                ),
                ButtonSegment(
                  value: DailyCapacity.medium,
                  label: Text('Medium'),
                  icon: Icon(Icons.battery_4_bar_rounded),
                ),
                ButtonSegment(
                  value: DailyCapacity.high,
                  label: Text('High'),
                  icon: Icon(Icons.battery_full_rounded),
                ),
              ],
              selected: {widget.capacity},
              onSelectionChanged: (selection) {
                widget.onCapacityChanged(selection.single);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _capacityPlan(widget.capacity),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.moodState.selectedMood.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.moodState.moodPlanSuggestion,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              key: const Key('recovery-mode-toggle'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Recovery mode'),
              subtitle: Text(
                recoverySuggested
                    ? 'Suggested for this capacity or mood.'
                    : 'Use a reduced plan for a hard day.',
              ),
              value: _manualRecoveryMode,
              onChanged: (value) {
                setState(() => _manualRecoveryMode = value);
              },
            ),
            if (recoveryActive) ...[
              const SizedBox(height: AppSpacing.xs),
              _RecoveryPlan(
                onOpenMood: widget.onOpenMood,
                onStartTiny: _startTinyRecovery,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _capacityPlan(DailyCapacity capacity) {
    switch (capacity) {
      case DailyCapacity.low:
        return 'One tiny task is enough today. Setup counts.';
      case DailyCapacity.medium:
        return 'One task plus one focus session is the plan.';
      case DailyCapacity.high:
        return 'Pick two or three planned tasks, then protect one focus block.';
    }
  }

  void _startTinyRecovery() {
    final started = widget.timerState.startQuickFocus(2);
    widget.onOpenTimer?.call();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            started
                ? '2 minute recovery focus started'
                : 'A focus session is already active',
          ),
        ),
      );
  }
}

class _RecoveryPlan extends StatelessWidget {
  const _RecoveryPlan({
    required this.onOpenMood,
    required this.onStartTiny,
  });

  final VoidCallback? onOpenMood;
  final VoidCallback onStartTiny;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: cs.secondary.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recovery mode: 1 tiny task, 1 mood check-in, optional 2-minute focus.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OutlinedButton.icon(
                  key: const Key('recovery-mood-checkin'),
                  onPressed: onOpenMood ??
                      () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MoodTrackerScreen(),
                            ),
                          ),
                  icon: const Icon(Icons.mood_outlined),
                  label: const Text('Check mood'),
                ),
                FilledButton.icon(
                  key: const Key('recovery-start-tiny'),
                  onPressed: onStartTiny,
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text('Start 2 min'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyReviewCard extends StatelessWidget {
  const _DailyReviewCard({
    required this.taskState,
    required this.timerState,
    required this.settingsState,
    required this.reminderState,
  });

  final TaskState taskState;
  final TimerState timerState;
  final SettingsState settingsState;
  final TaskReminderState reminderState;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tomorrowStart = _tomorrowStart();
    final starterTask = taskState.tomorrowStarterTask;
    final starterOptions = taskState.tomorrowStarterOptions;
    final selectedStarter = taskState.selectedTomorrowStarterTask;
    final starterReminder =
        starterTask == null ? null : reminderState.reminderFor(starterTask.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.nights_stay_outlined, color: cs.secondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'What counted today?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _countedLine(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _ReviewPrompt(
              icon: Icons.favorite_border_rounded,
              label: 'What helped?',
            ),
            const SizedBox(height: AppSpacing.xs),
            _ReviewPrompt(
              icon: Icons.flag_outlined,
              label: 'Tomorrow start with $tomorrowStart.',
            ),
            if (starterOptions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int>(
                key: const Key('tomorrow-starter-menu'),
                value: selectedStarter?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tomorrow starter',
                  isDense: true,
                ),
                hint: const Text('Choose first task'),
                items: [
                  for (final task in starterOptions)
                    DropdownMenuItem(
                      value: task.id,
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (taskId) {
                  if (taskId == null) return;
                  taskState.setTomorrowStarter(taskId);
                },
              ),
            ],
            if (starterTask != null) ...[
              const SizedBox(height: AppSpacing.sm),
              if (starterReminder != null) ...[
                _ReminderStatusLine(reminder: starterReminder),
                const SizedBox(height: AppSpacing.xs),
              ],
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  FilledButton.icon(
                    key: const Key('daily-review-remind-tomorrow'),
                    onPressed: () => _remindTomorrow(context, starterTask),
                    icon: const Icon(Icons.notifications_none_rounded),
                    label: const Text('Remind tomorrow'),
                  ),
                  if (starterReminder != null)
                    OutlinedButton.icon(
                      key: const Key('daily-review-cancel-reminder'),
                      onPressed: () =>
                          _cancelReminder(context, starterReminder.taskId),
                      icon: const Icon(Icons.notifications_off_outlined),
                      label: const Text('Cancel nudge'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _countedLine() {
    if (timerState.focusMinutesToday > 0) {
      return '${timerState.focusMinutesToday}m of focus counted.';
    }
    if (taskState.completedTasksToday > 0) {
      return '${taskState.completedTasksToday} task finished today counted.';
    }
    if (taskState.completedSubtasks > 0) {
      return '${taskState.completedSubtasks} tiny steps counted.';
    }
    return 'You showed up. That counted.';
  }

  String _tomorrowStart() {
    return taskState.tomorrowStarterTask?.title ?? 'a mood check-in';
  }

  Future<void> _remindTomorrow(BuildContext context, Task task) async {
    if (!settingsState.taskRemindersEnabled) {
      _message(context, 'Turn on Task nudges in Settings first.');
      return;
    }

    final tinyStep = taskState.tinyStepSuggestionFor(task);
    final scheduled = await reminderState.remindTomorrow(
      task,
      tinyStep: tinyStep,
      style: settingsState.taskReminderStyle,
    );
    if (!context.mounted) return;
    _message(
      context,
      scheduled
          ? 'Reminder set for tomorrow'
          : reminderState.lastError ?? 'Could not set reminder.',
    );
  }

  Future<void> _cancelReminder(BuildContext context, int taskId) async {
    try {
      await reminderState.cancelReminder(taskId);
      if (context.mounted) _message(context, 'Reminder canceled');
    } catch (_) {
      if (context.mounted) _message(context, 'Could not cancel that reminder.');
    }
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReviewPrompt extends StatelessWidget {
  const _ReviewPrompt({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
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
                        moodState.moodPlanSuggestion,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
                    color: cs.primary.withOpacity(0.1),
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
              color: primary ? cs.primary : cs.primary.withOpacity(0.08),
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

class _NextPreview extends StatefulWidget {
  const _NextPreview({
    required this.timerState,
    required this.dailyPlan,
    required this.onOpenTimer,
  });

  final TimerState timerState;
  final DailyPlan dailyPlan;
  final VoidCallback? onOpenTimer;

  @override
  State<_NextPreview> createState() => _NextPreviewState();
}

class _NextPreviewState extends State<_NextPreview> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final tasks = widget.dailyPlan.nextTasks;
    final laterCount = widget.dailyPlan.laterCount;
    final resumeCandidate = widget.timerState.isActiveFocusSession
        ? null
        : widget.dailyPlan.resumeSuggestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label: 'Next tasks, ${tasks.length}',
          child: InkWell(
            key: const Key('dashboard-next-toggle'),
            borderRadius: BorderRadius.circular(AppRadii.control),
            onTap: () => setState(() => _expanded = !_expanded),
            child: SizedBox(
              height: AppSizes.minimumTouchTarget,
              child: Row(
                children: [
                  Text(
                    'Next',
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
          if (resumeCandidate != null) ...[
            _ResumeFocusTile(
              candidate: resumeCandidate,
              onStart: () => _startResumeFocus(resumeCandidate),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (tasks.isEmpty && resumeCandidate == null)
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
                child: _UpcomingTile(
                  task: task,
                  insight: widget.dailyPlan.insightFor(task.id),
                ),
              ),
            ),
        ],
        if (laterCount > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          _LaterSummary(count: laterCount),
        ],
      ],
    );
  }

  void _startResumeFocus(PlannedTask candidate) {
    final session = candidate.insight.resumeSession;
    if (session == null) return;

    final started = widget.timerState.startTargetFocus(
      minutes: 5,
      targetType: session.targetType,
      taskId: candidate.task.id,
      subtaskId: session.targetType == TimerState.targetTypeSubtask
          ? session.subtaskId
          : null,
      title: candidate.insight.targetTitle ?? candidate.task.title,
    );
    if (started) {
      widget.onOpenTimer?.call();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('A focus session is already running.')),
      );
  }
}

class _ResumeFocusTile extends StatelessWidget {
  const _ResumeFocusTile({
    required this.candidate,
    required this.onStart,
  });

  final PlannedTask candidate;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final compact = MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).width < 390;
    final session = candidate.insight.resumeSession;
    final targetTitle = candidate.insight.targetTitle ?? candidate.task.title;
    final isSubtask = session?.targetType == TimerState.targetTypeSubtask;
    final detail = isSubtask
        ? '$targetTitle · ${candidate.task.title}'
        : candidate.task.title;
    final button = OutlinedButton.icon(
      key: const Key('dashboard-resume-focus'),
      onPressed: onStart,
      icon: const Icon(Icons.play_arrow_rounded),
      label: const Text('Start 5 min'),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
    );

    final titleRow = Row(
      children: [
        Icon(Icons.history_rounded, color: cs.primary, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Still open',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRow,
        const SizedBox(height: AppSpacing.xxs),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          session == null
              ? candidate.insight.reason
              : 'Left open ${DateFormat.jm().format(session.endedAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: cs.primary.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  textBlock,
                  const SizedBox(height: AppSpacing.xs),
                  Align(alignment: Alignment.centerLeft, child: button),
                ],
              )
            : Row(
                children: [
                  Expanded(child: textBlock),
                  const SizedBox(width: AppSpacing.xs),
                  button,
                ],
              ),
      ),
    );
  }
}

class _LaterSummary extends StatelessWidget {
  const _LaterSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: cs.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text('Later', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.xs),
            _CountPill(count: count),
            const Spacer(),
            Text(
              'tucked away',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
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
        color: cs.primary.withOpacity(0.12),
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
  const _UpcomingTile({required this.task, this.insight});

  final Task task;
  final DailyPlanTaskInsight? insight;

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(task.dueDate);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: color.withOpacity(0.22)),
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
                    _detailLine(),
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

  String _detailLine() {
    final dueLine =
        '${DateFormat.MMMd().format(task.dueDate)} - ${_countdown(task.dueDate)}';
    final reason = insight?.reason;
    if (reason == null || reason.isEmpty) return dueLine;
    return '$dueLine - $reason';
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
