import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final currentModeIndex = _modes.indexOf(timerState.currentMode);
    final modeIndex = currentModeIndex >= 0 ? currentModeIndex : 0;
    final color = _modeColors[modeIndex];
    final completionMessage = timerState.completionMessage;

    if (completionMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final timerState = context.read<TimerState>();
        final message = timerState.completionMessage;
        if (message == null) return;
        final linkedTarget = timerState.pendingCompletionTarget;
        timerState.clearCompletionMessage();
        _showCompletionPrompt(message, linkedTarget);
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

  void _showCompletionPrompt(
    String detail,
    TimerCompletionTarget? linkedTarget,
  ) {
    if (linkedTarget == null) {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => _CompletionPromptSheet(
          detail: detail,
          onKeepGoing: () {
            Navigator.pop(sheetContext);
            if (!mounted) return;
            context.read<TimerState>().startQuickFocus(5);
          },
          onDone: () => Navigator.pop(sheetContext),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => _LinkedCompletionPromptSheet(
        target: linkedTarget,
        onMarkComplete: () {
          Navigator.pop(sheetContext);
          unawaited(_markLinkedComplete(linkedTarget));
        },
        onAddFive: () {
          Navigator.pop(sheetContext);
          unawaited(_continueLinkedFocus());
        },
        onLeaveOpen: () {
          Navigator.pop(sheetContext);
          unawaited(
            context
                .read<TimerState>()
                .resolveLinkedCompletion(TimerState.outcomeLeftOpen),
          );
        },
        onTakeBreak: () {
          Navigator.pop(sheetContext);
          unawaited(
            context
                .read<TimerState>()
                .resolveLinkedCompletion(TimerState.outcomeBreakReady),
          );
        },
      ),
    );
  }

  Future<void> _markLinkedComplete(TimerCompletionTarget target) async {
    try {
      final taskState = context.read<TaskState>();
      final timerState = context.read<TimerState>();
      if (target.isSubtask) {
        await taskState.completeSubtask(target.taskId, target.subtaskId!);
        await timerState.resolveLinkedCompletion(
          TimerState.outcomeSubtaskCompleted,
        );
      } else {
        await taskState.completeTask(target.taskId);
        await timerState
            .resolveLinkedCompletion(TimerState.outcomeTaskCompleted);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark that complete.')),
      );
    }
  }

  Future<void> _continueLinkedFocus() async {
    final started = await context.read<TimerState>().continueLinkedFocus();
    if (started || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not add more time.')),
    );
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
                  color: color.withValues(alpha: 0.78),
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
    required this.onKeepGoing,
    required this.onDone,
  });

  final String detail;
  final VoidCallback onKeepGoing;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
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
              'Want to keep going or stop here?',
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
              label: const Text('Keep going'),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton(
              key: const Key('completion-done-for-now'),
              onPressed: onDone,
              child: const Text('Done for now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedCompletionPromptSheet extends StatelessWidget {
  const _LinkedCompletionPromptSheet({
    required this.target,
    required this.onMarkComplete,
    required this.onAddFive,
    required this.onLeaveOpen,
    required this.onTakeBreak,
  });

  final TimerCompletionTarget target;
  final VoidCallback onMarkComplete;
  final VoidCallback onAddFive;
  final VoidCallback onLeaveOpen;
  final VoidCallback onTakeBreak;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final markLabel =
        target.isSubtask ? 'Mark step complete' : 'Mark task complete';

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
              Icon(Icons.flag_rounded, color: cs.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Did that get finished?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                target.title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                key: const Key('linked-completion-mark-complete'),
                onPressed: onMarkComplete,
                icon: const Icon(Icons.check_rounded),
                label: Text(markLabel),
              ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                key: const Key('linked-completion-add-five'),
                onPressed: onAddFive,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Add 5 min'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      key: const Key('linked-completion-leave-open'),
                      onPressed: onLeaveOpen,
                      child: const Text('Leave open'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: TextButton(
                      key: const Key('linked-completion-take-break'),
                      onPressed: onTakeBreak,
                      child: const Text('Take break'),
                    ),
                  ),
                ],
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
          onTap: timerState.switchToNextMode,
          color: cs.onSurface.withOpacity(0.08),
          iconColor: cs.onSurfaceVariant,
          size: 52,
        ),
      ],
    );
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
