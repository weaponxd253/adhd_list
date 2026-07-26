import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/timer_state.dart';
import '../../theme/app_theme.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = context.watch<TimerState>();
    final currentModeIndex = _modes.indexOf(timerState.currentMode);
    final modeIndex = currentModeIndex >= 0 ? currentModeIndex : 0;
    final color = _modeColors[modeIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
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
              SizedBox(height: compact ? AppSpacing.xl : 48),
              _TimerControls(timerState: timerState, color: color),
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
              _SessionLengths(timerState: timerState, colors: _modeColors),
            ],
          );
        },
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

    return Center(
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
        Semantics(
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
