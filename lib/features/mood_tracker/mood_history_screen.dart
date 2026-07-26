import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/mood_state.dart';
import '../../theme/app_theme.dart';

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodState>(
      builder: (context, moodState, _) {
        final history = moodState.moodHistoryList;
        final groups = _groupByDate(history);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mood History'),
          ),
          body: history.isEmpty
              ? const _EmptyMoodHistory()
              : ListView.separated(
                  padding: AppInsets.screenScrollPadding(context),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return _MoodHistoryGroupView(group: groups[index]);
                  },
                ),
        );
      },
    );
  }

  static List<_MoodHistoryGroup> _groupByDate(
    List<Map<String, dynamic>> history,
  ) {
    final dated = <DateTime, List<Map<String, dynamic>>>{};
    final unknownDate = <Map<String, dynamic>>[];

    for (final entry in history) {
      final parsed = _parseDate(entry['date']);
      if (parsed == null) {
        unknownDate.add(entry);
        continue;
      }

      final day = DateUtils.dateOnly(parsed);
      dated.putIfAbsent(day, () => []).add(entry);
    }

    final groups = dated.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return [
      for (final group in groups)
        _MoodHistoryGroup(date: group.key, entries: group.value),
      if (unknownDate.isNotEmpty)
        _MoodHistoryGroup(date: null, entries: unknownDate),
    ];
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}

class _MoodHistoryGroup {
  const _MoodHistoryGroup({
    required this.date,
    required this.entries,
  });

  final DateTime? date;
  final List<Map<String, dynamic>> entries;
}

class _MoodHistoryGroupView extends StatelessWidget {
  const _MoodHistoryGroupView({required this.group});

  final _MoodHistoryGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _dayLabel(group.date),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final entry in group.entries) ...[
          _MoodHistoryTile(entry: entry),
          if (entry != group.entries.last)
            const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  String _dayLabel(DateTime? date) {
    if (date == null) return 'Unknown date';

    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(date);
    final difference = today.difference(day).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat.yMMMMd().format(date);
  }
}

class _MoodHistoryTile extends StatelessWidget {
  const _MoodHistoryTile({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mood = entry['mood'] as String? ?? 'Unknown mood';
    final emoji = entry['emoji'] as String? ?? '\u{1F60A}';
    final date = DateTime.tryParse(entry['date'] as String? ?? '')?.toLocal();

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
          SizedBox(
            width: 40,
            child: Text(
              emoji,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  date == null ? 'Unknown time' : DateFormat.jm().format(date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMoodHistory extends StatelessWidget {
  const _EmptyMoodHistory();

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
              Icons.history_rounded,
              size: 56,
              color: cs.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No mood history yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Log a mood to start seeing your patterns over time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
