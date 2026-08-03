import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mood_state.dart';
import '../../theme/app_theme.dart';
import '../mood_tracker/mood_history_screen.dart';

class MoodTrackerScreen extends StatelessWidget {
  const MoodTrackerScreen({super.key});

  static const _moods = [
    {'e': '🌱', 'l': 'Hopeful'},
    {'e': '🧘', 'l': 'Calm'},
    {'e': '🌞', 'l': 'Optimistic'},
    {'e': '😃', 'l': 'Joyful'},
    {'e': '🤩', 'l': 'Excited'},
    {'e': '✨', 'l': 'Inspired'},
    {'e': '✊', 'l': 'Empowered'},
    {'e': '🍀', 'l': 'Grateful'},
    {'e': '😌', 'l': 'Relaxed'},
    {'e': '🧠', 'l': 'Mindful'},
    {'e': '🌍', 'l': 'Grounded'},
    {'e': '🤗', 'l': 'Validated'},
    {'e': '💬', 'l': 'Encouraged'},
    {'e': '💖', 'l': 'Accepted'},
    {'e': '😔', 'l': 'Sad'},
    {'e': '😟', 'l': 'Worried'},
    {'e': '😨', 'l': 'Anxious'},
    {'e': '😤', 'l': 'Frustrated'},
    {'e': '😡', 'l': 'Angry'},
    {'e': '💧', 'l': 'Vulnerable'},
    {'e': '❄️', 'l': 'Disconnected'},
    {'e': '🌀', 'l': 'Distracted'},
    {'e': '🔥', 'l': 'Burnt Out'},
    {'e': '⚠️', 'l': 'Triggered'},
    {'e': '🚫', 'l': 'Rejected'},
    {'e': '🖤', 'l': 'Grieving'},
  ];

  Future<void> _saveMood(
    BuildContext context,
    MoodState moodState,
    String mood,
    String emoji,
  ) async {
    try {
      await moodState.setMood(mood, emoji);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your mood. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodState>(
      builder: (context, moodState, _) {
        final cs = Theme.of(context).colorScheme;
        final selected = moodState.selectedMood;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mood'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Mood history',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodHistoryScreen()),
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selected.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        moodState.selectedMoodEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: cs.primary),
                            ),
                            Text(
                              moodState.moodMessage,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: _MoodGrid(
                  moods: _moods,
                  selected: selected,
                  onSelected: (mood) => _saveMood(
                    context,
                    moodState,
                    mood['l']!,
                    mood['e']!,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoodGrid extends StatelessWidget {
  const _MoodGrid({
    required this.moods,
    required this.selected,
    required this.onSelected,
  });

  final List<Map<String, String>> moods;
  final String selected;
  final ValueChanged<Map<String, String>> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const tileGap = AppSpacing.sm;
        final availableWidth = constraints.maxWidth - AppSpacing.md * 2;
        final tileWidth = (availableWidth - tileGap * (columns - 1)) / columns;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final tileHeight =
            tileWidth / 1.08 + (textScale > 1.2 ? (textScale - 1.2) * 28 : 0);

        return ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppInsets.bottomNavigationScrollPadding(context),
          ),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: tileGap,
              runSpacing: tileGap,
              children: [
                for (final mood in moods)
                  SizedBox(
                    width: tileWidth,
                    height: tileHeight,
                    child: _MoodCell(
                      emoji: mood['e']!,
                      label: mood['l']!,
                      isSelected: selected == mood['l'],
                      onTap: () => onSelected(mood),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MoodCell extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _MoodCell({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedFill = Color.alphaBlend(
      cs.primary.withValues(alpha: isDark ? 0.18 : 0.10),
      cs.surface,
    );

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Select $label mood',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? selectedFill : cs.surface,
              borderRadius: BorderRadius.circular(AppRadii.control),
              border: Border.all(
                color: isSelected ? cs.primary : cs.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: AppSpacing.xxs),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? cs.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
