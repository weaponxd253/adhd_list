import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timer_state.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  static const _modes = ['Focus', 'Short Break', 'Long Break'];
  static const _modeEmojis = ['🎯', '☕', '😴'];
  static const _modeColors = [
    Color(0xFF5B5BD6),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
  ];

  late AnimationController _pulseController;

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
    final timerState = Provider.of<TimerState>(context);
    final currentModeIndex = _modes.indexOf(timerState.currentMode);
    final modeIndex = currentModeIndex >= 0 ? currentModeIndex : 0;
    final color = _modeColors[modeIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Mode selector ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0FA),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: List.generate(_modes.length, (i) {
                  final sel = i == modeIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => timerState.setMode(_modes[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? _modeColors[i] : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                      color: _modeColors[i].withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Text(_modeEmojis[i],
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(
                              _modes[i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 48),

            // ── Circular timer ───────────────────────────────────────
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow (pulse when running)
                  if (timerState.isTimerRunning)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Container(
                        width: 240 + _pulseController.value * 16,
                        height: 240 + _pulseController.value * 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              color.withOpacity(0.06 * _pulseController.value),
                        ),
                      ),
                    ),

                  // Ring
                  CustomPaint(
                    size: const Size(240, 240),
                    painter: _RingPainter(
                      progress: timerState.progress,
                      color: color,
                      trackColor: color.withOpacity(0.1),
                    ),
                  ),

                  // Center content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _modeEmojis[modeIndex],
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timerState.timerDisplay,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: -2,
                        ),
                      ),
                      Text(
                        timerState.currentMode,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // ── Controls ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset
                _CircleButton(
                  icon: Icons.refresh_rounded,
                  onTap: timerState.resetTimer,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                  iconColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  size: 52,
                ),
                const SizedBox(width: 20),

                // Play / Pause (primary)
                GestureDetector(
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
                            color: color.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4)),
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
                const SizedBox(width: 20),

                // Skip
                _CircleButton(
                  icon: Icons.skip_next_rounded,
                  onTap: timerState.switchToNextMode,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                  iconColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  size: 52,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Session info ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoChip(
                    label: 'Focus',
                    value: '${timerState.focusDuration}m',
                    color: _modeColors[0]),
                const SizedBox(width: 12),
                _InfoChip(
                    label: 'Short',
                    value: '${timerState.shortBreakDuration}m',
                    color: _modeColors[1]),
                const SizedBox(width: 12),
                _InfoChip(
                    label: 'Long',
                    value: '${timerState.longBreakDuration}m',
                    color: _modeColors[2]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  const _RingPainter(
      {required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - 16) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track
    canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round);

    // Progress
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: -math.pi / 2 + 2 * math.pi * progress,
            colors: [color.withOpacity(0.5), color],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;
  final double size;
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.iconColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: size * 0.44),
        ),
      );
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.6))),
          ],
        ),
      );
}
