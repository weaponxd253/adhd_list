import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/focus_session.dart';
import '../../providers/timer_state.dart';
import '../../theme/app_theme.dart';

class TimerHistoryScreen extends StatefulWidget {
  const TimerHistoryScreen({super.key});

  @override
  State<TimerHistoryScreen> createState() => _TimerHistoryScreenState();
}

class _TimerHistoryScreenState extends State<TimerHistoryScreen> {
  bool _requestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedLoad) return;
    _requestedLoad = true;
    final timerState = context.read<TimerState>();
    Future.microtask(timerState.loadSessionHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerState>(
      builder: (context, timerState, _) {
        final sessions = timerState.sessionHistory;
        final groups = _groups(sessions);

        return Scaffold(
          appBar: AppBar(title: const Text('Timer History')),
          body: timerState.isSessionHistoryLoading && sessions.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Loading timer history',
                  ),
                )
              : sessions.isEmpty
                  ? _EmptyTimerHistory(error: timerState.sessionHistoryError)
                  : RefreshIndicator(
                      onRefresh: timerState.loadSessionHistory,
                      child: ListView.separated(
                        padding: AppInsets.screenScrollPadding(context),
                        itemCount: groups.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return _SessionGroupView(group: group);
                        },
                      ),
                    ),
        );
      },
    );
  }

  List<_SessionGroup> _groups(List<FocusSession> sessions) {
    final grouped = <DateTime, List<FocusSession>>{};
    for (final session in sessions) {
      final day = DateTime(
        session.endedAt.year,
        session.endedAt.month,
        session.endedAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(session);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return [
      for (final entry in entries)
        _SessionGroup(date: entry.key, sessions: entry.value),
    ];
  }
}

class _SessionGroup {
  const _SessionGroup({
    required this.date,
    required this.sessions,
  });

  final DateTime date;
  final List<FocusSession> sessions;
}

class _SessionGroupView extends StatelessWidget {
  const _SessionGroupView({required this.group});

  final _SessionGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_dayLabel(group.date),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        for (final session in group.sessions) ...[
          _SessionTile(session: session),
          if (session != group.sessions.last)
            const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat.yMMMMd().format(date);
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _modeColor(session.mode, cs);
    final targetLabel = _targetLabel(session);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 44,
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
                  session.mode,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (targetLabel != null)
                  Text(
                    targetLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                Text(
                  '${session.durationMinutes} min • ${DateFormat.jm().format(session.endedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            session.completed
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
          ),
        ],
      ),
    );
  }

  Color _modeColor(String mode, ColorScheme cs) {
    switch (mode) {
      case 'Short Break':
        return const Color(0xFF0EA5E9);
      case 'Long Break':
        return const Color(0xFF8B5CF6);
      default:
        return cs.primary;
    }
  }

  String? _targetLabel(FocusSession session) {
    final title = session.targetTitleSnapshot?.trim();
    if (title == null || title.isEmpty) return null;

    if (session.targetType == TimerState.targetTypeSubtask) {
      return 'Step: $title';
    }
    if (session.targetType == TimerState.targetTypeTask) {
      return 'Task: $title';
    }
    return null;
  }
}

class _EmptyTimerHistory extends StatelessWidget {
  const _EmptyTimerHistory({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error == null ? Icons.history_rounded : Icons.cloud_off_rounded,
              size: 56,
              color: error == null ? cs.primary : cs.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              error == null ? 'No timer sessions yet' : 'History unavailable',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error ?? 'Complete a focus timer to start building history.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
