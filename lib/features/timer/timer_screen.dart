import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/focus_session.dart';
import '../../models/subtask.dart';
import '../../models/task.dart';
import '../../providers/task_state.dart';
import '../../providers/timer_state.dart';
import '../../theme/app_theme.dart';
import 'timer_history_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _modes = ['Focus', 'Short Break', 'Long Break'];
  static const _modeEmojis = ['\u{1F3AF}', '\u{2615}', '\u{1F634}'];
  static const _modeColors = [
    Color(0xFF5B5BD6),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
  ];

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    context.read<TimerState>().syncWithClock();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = context.watch<TimerState>();
    final taskState = context.watch<TaskState?>();
    final currentModeIndex = _modes.indexOf(timerState.currentMode);
    final modeIndex = currentModeIndex >= 0 ? currentModeIndex : 0;
    final color = _modeColors[modeIndex];
    final completionMessage = timerState.completionMessage;
    final completedSession = timerState.lastCompletedSession;
    final activeTask = _taskFor(taskState, timerState.activeTaskId);
    final activeSubtask = _subtaskFor(activeTask, timerState.activeSubtaskId);

    if (completionMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final timerState = context.read<TimerState>();
        final message = timerState.completionMessage;
        final session = timerState.lastCompletedSession ?? completedSession;
        if (message == null) return;
        timerState.clearCompletionMessage();
        _showCompletionPrompt(message, session);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        actions: [
          IconButton(
            tooltip: 'Timer history',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TimerHistoryScreen()),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          final ringSize = math.min(
            240.0,
            math.max(188.0, constraints.maxWidth - AppSpacing.xl * 2),
          );

          return ListView(
            key: const PageStorageKey('timer-scroll'),
            padding: AppInsets.screenScrollPadding(
              context,
              left: AppSpacing.lg,
              top: compact ? AppSpacing.md : AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xl,
            ),
            children: [
              _ModeSelector(
                modes: _modes,
                emojis: _modeEmojis,
                colors: _modeColors,
                selectedIndex: modeIndex,
                onSelected: timerState.setMode,
              ),
              SizedBox(height: compact ? AppSpacing.xl : 48),
              _TimerRing(
                size: ringSize,
                timerState: timerState,
                color: color,
                pulse: _pulseController,
                emoji: _modeEmojis[modeIndex],
              ),
              const SizedBox(height: AppSpacing.md),
              if (activeTask != null)
                _CurrentTargetCard(
                  timerState: timerState,
                  task: activeTask,
                  subtask: activeSubtask,
                  focusMinutes: timerState.focusMinutesForTask(activeTask.id),
                  onMarkDone: taskState == null
                      ? null
                      : () => _markActiveTargetDone(taskState, timerState),
                )
              else
                _TimerTargetLabel(timerState: timerState, color: color),
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
              _TimerControls(timerState: timerState, color: color),
              const SizedBox(height: AppSpacing.sm),
              _TimerStatusChip(label: timerState.statusLabel, color: color),
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
              _SessionLengths(timerState: timerState, colors: _modeColors),
            ],
          );
        },
      ),
    );
  }

  void _showCompletionPrompt(String detail, FocusSession? completedSession) {
    final canTakeBreak = completedSession?.mode == 'Focus';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _CompletionPromptSheet(
        detail: detail,
        countedLine: _countedLineFor(completedSession),
        onKeepGoing: () {
          Navigator.pop(sheetContext);
          if (!mounted) return;
          _startFollowUpFocus(completedSession);
        },
        markDoneLabel: _markDoneLabel(completedSession),
        onMarkTargetDone: _canMarkDone(completedSession)
            ? () => _markTargetDone(sheetContext, completedSession!)
            : null,
        doneLabel: canTakeBreak ? 'Take break' : 'Done for now',
        onDone: () {
          Navigator.pop(sheetContext);
          if (!mounted || !canTakeBreak) return;
          context.read<TimerState>().startTimer();
        },
      ),
    );
  }

  Task? _taskFor(TaskState? taskState, int? taskId) {
    if (taskState == null || taskId == null) return null;
    for (final task in taskState.tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  Subtask? _subtaskFor(Task? task, int? subtaskId) {
    if (task == null || subtaskId == null) return null;
    for (final subtask in task.subtasks) {
      if (subtask.id == subtaskId) return subtask;
    }
    return null;
  }

  String _countedLineFor(FocusSession? session) {
    if (session == null) return 'This session counted.';

    final minutes = session.durationMinutes;
    final target = session.targetTitleSnapshot?.trim();
    if (session.mode == 'Focus' && target != null && target.isNotEmpty) {
      return '${minutes}m counted toward $target.';
    }
    if (session.mode == 'Focus') return '${minutes}m focus counted.';
    return '${minutes}m ${session.mode.toLowerCase()} counted.';
  }

  void _startFollowUpFocus(FocusSession? completedSession) {
    final timerState = context.read<TimerState>();
    if (_canResumeTarget(completedSession)) {
      timerState.startTargetFocus(
        minutes: 5,
        targetType: completedSession!.targetType,
        taskId: completedSession.taskId,
        subtaskId: completedSession.subtaskId,
        title: completedSession.targetTitleSnapshot,
      );
      return;
    }

    timerState.startQuickFocus(5);
  }

  bool _canResumeTarget(FocusSession? session) {
    if (session == null || session.mode != 'Focus') return false;
    if (session.targetType == TimerState.targetTypeTask) {
      return session.taskId != null;
    }
    if (session.targetType == TimerState.targetTypeSubtask) {
      return session.taskId != null && session.subtaskId != null;
    }
    return false;
  }

  bool _canMarkDone(FocusSession? session) => _markDoneLabel(session) != null;

  String? _markDoneLabel(FocusSession? session) {
    if (!_canResumeTarget(session)) return null;
    if (session!.targetType == TimerState.targetTypeSubtask) {
      return 'Mark step done';
    }
    return 'Mark task done';
  }

  Future<void> _markTargetDone(
    BuildContext sheetContext,
    FocusSession session,
  ) async {
    final isSubtask = session.targetType == TimerState.targetTypeSubtask;
    try {
      final taskState = context.read<TaskState>();
      final changed = isSubtask
          ? await taskState.markSubtaskCompleted(
              session.taskId!,
              session.subtaskId!,
            )
          : await taskState.markTaskCompleted(session.taskId!);
      if (!mounted || !sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      _showMessage(
        changed
            ? isSubtask
                ? 'Step marked done'
                : 'Task marked done'
            : isSubtask
                ? 'Step already done'
                : 'Task already done',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update the task.');
    }
  }

  Future<void> _markActiveTargetDone(
    TaskState taskState,
    TimerState timerState,
  ) async {
    try {
      final isSubtask =
          timerState.activeTargetType == TimerState.targetTypeSubtask;
      final changed = isSubtask
          ? await taskState.markSubtaskCompleted(
              timerState.activeTaskId!,
              timerState.activeSubtaskId!,
            )
          : await taskState.markTaskCompleted(timerState.activeTaskId!);
      if (!mounted) return;
      _showMessage(
        changed
            ? isSubtask
                ? 'Step marked done'
                : 'Task marked done'
            : isSubtask
                ? 'Step already done'
                : 'Task already done',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update the task.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TimerTargetLabel extends StatelessWidget {
  const _TimerTargetLabel({
    required this.timerState,
    required this.color,
  });

  final TimerState timerState;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final title = timerState.activeTargetTitle;
    final hasTitle = timerState.hasActiveTarget && title != null;
    final label = hasTitle ? 'Working on' : 'Focus session';
    final detail = hasTitle ? title : null;

    return Semantics(
      label: detail == null ? label : '$label $detail',
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.78),
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentTargetCard extends StatelessWidget {
  const _CurrentTargetCard({
    required this.timerState,
    required this.task,
    required this.subtask,
    required this.focusMinutes,
    required this.onMarkDone,
  });

  final TimerState timerState;
  final Task task;
  final Subtask? subtask;
  final int focusMinutes;
  final VoidCallback? onMarkDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completedSteps =
        task.subtasks.where((item) => item.isCompleted).length;
    final totalSteps = task.subtasks.length;
    final activeStep = subtask;
    final canMarkDone =
        onMarkDone != null && !(activeStep?.isCompleted ?? task.isCompleted);
    final markLabel =
        timerState.activeTargetType == TimerState.targetTypeSubtask
            ? 'Mark step done'
            : 'Mark task done';
    final meta = <String>[
      if (totalSteps > 0) '$completedSteps/$totalSteps steps',
      if (focusMinutes > 0) '${focusMinutes}m focus',
    ];

    return Semantics(
      container: true,
      label: 'Current task ${task.title}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Current task',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  meta.join(' - '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (activeStep != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Working on: ${activeStep.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
              if (canMarkDone) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('timer-current-mark-done'),
                    onPressed: onMarkDone,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(markLabel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerStatusChip extends StatelessWidget {
  const _TimerStatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionPromptSheet extends StatelessWidget {
  const _CompletionPromptSheet({
    required this.detail,
    required this.countedLine,
    required this.onKeepGoing,
    required this.markDoneLabel,
    required this.onMarkTargetDone,
    required this.doneLabel,
    required this.onDone,
  });

  final String detail;
  final String countedLine;
  final VoidCallback onKeepGoing;
  final String? markDoneLabel;
  final Future<void> Function()? onMarkTargetDone;
  final String doneLabel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded, color: cs.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'That counted.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                countedLine,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                key: const Key('completion-keep-going'),
                onPressed: onKeepGoing,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Keep going 5m'),
              ),
              if (markDoneLabel != null && onMarkTargetDone != null) ...[
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton.icon(
                  key: const Key('completion-mark-target-done'),
                  onPressed: () => onMarkTargetDone!(),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(markDoneLabel!),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton(
                key: const Key('completion-done-for-now'),
                onPressed: onDone,
                child: Text(doneLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.modes,
    required this.emojis,
    required this.colors,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> modes;
  final List<String> emojis;
  final List<Color> colors;
  final int selectedIndex;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Row(
        children: List.generate(modes.length, (index) {
          final selected = index == selectedIndex;
          final color = colors[index];

          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: '${modes[index]} timer mode',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(modes[index]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: selected ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.control - 2),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(emojis[index], style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        modes[index],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : cs.onSurfaceVariant,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({
    required this.size,
    required this.timerState,
    required this.color,
    required this.pulse,
    required this.emoji,
  });

  final double size;
  final TimerState timerState;
  final Color color;
  final Animation<double> pulse;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = color.withOpacity(isDark ? 0.22 : 0.16);

    return Semantics(
      liveRegion: timerState.isTimerRunning,
      label: '${timerState.currentMode} timer',
      value: '${timerState.timerDisplay} remaining, ${timerState.statusLabel}',
      child: ExcludeSemantics(
        child: Center(
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (timerState.isTimerRunning)
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (_, __) => Container(
                      width: size + pulse.value * 16,
                      height: size + pulse.value * 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.06 * pulse.value),
                      ),
                    ),
                  ),
                CustomPaint(
                  size: Size.square(size),
                  painter: _RingPainter(
                    progress: timerState.progress.clamp(0, 1).toDouble(),
                    color: color,
                    trackColor: trackColor,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      timerState.timerDisplay,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      timerState.currentMode,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color.withOpacity(0.78),
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  const _TimerControls({
    required this.timerState,
    required this.color,
  });

  final TimerState timerState;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: Icons.refresh_rounded,
          label: 'Reset timer',
          onTap: timerState.resetTimer,
          color: cs.onSurface.withOpacity(0.08),
          iconColor: cs.onSurfaceVariant,
          size: 52,
        ),
        const SizedBox(width: AppSpacing.lg),
        Tooltip(
          message: timerState.isTimerRunning ? 'Pause timer' : 'Start timer',
          child: Semantics(
            button: true,
            label: timerState.isTimerRunning ? 'Pause timer' : 'Start timer',
            child: GestureDetector(
              onTap: timerState.isTimerRunning
                  ? timerState.pauseTimer
                  : timerState.startTimer,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.36),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  timerState.isTimerRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        _CircleButton(
          icon: Icons.skip_next_rounded,
          label: 'Skip to next mode',
          onTap: () => _skipToNextMode(context),
          color: cs.onSurface.withOpacity(0.08),
          iconColor: cs.onSurfaceVariant,
          size: 52,
        ),
      ],
    );
  }

  Future<void> _skipToNextMode(BuildContext context) async {
    if (!timerState.isTimerRunning) {
      timerState.switchToNextMode();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Skip this session?'),
          content: const Text('Time from this session will not be counted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Skip'),
            ),
          ],
        );
      },
    );
    if (!context.mounted || confirmed != true) return;
    timerState.switchToNextMode();
  }
}

class _SessionLengths extends StatelessWidget {
  const _SessionLengths({
    required this.timerState,
    required this.colors,
  });

  final TimerState timerState;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoChip(
          label: 'Focus',
          value: '${timerState.focusDuration}m',
          color: colors[0],
        ),
        const SizedBox(height: AppSpacing.xs),
        _InfoChip(
          label: 'Short',
          value: '${timerState.shortBreakDuration}m',
          color: colors[1],
        ),
        const SizedBox(height: AppSpacing.xs),
        _InfoChip(
          label: 'Long',
          value: '${timerState.longBreakDuration}m',
          color: colors[2],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: [color.withOpacity(0.72), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) {
    return old.progress != progress ||
        old.color != color ||
        old.trackColor != trackColor;
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.iconColor,
    required this.size,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: size * 0.44),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.68),
            ),
          ),
        ],
      ),
    );
  }
}
