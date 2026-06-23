import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mood_state.dart';
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
              // Current mood banner
              if (selected.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(moodState.selectedMoodEmoji,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              // 3-column grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _moods.length,
                  itemBuilder: (context, i) {
                    final mood = _moods[i];
                    final isSelected = selected == mood['l'];
                    return _MoodCell(
                      emoji: mood['e']!,
                      label: mood['l']!,
                      isSelected: isSelected,
                      onTap: () => _saveMood(
                        context,
                        moodState,
                        mood['l']!,
                        mood['e']!,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withOpacity(0.12)
              : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : (isDark ? const Color(0xFF2D2D44) : const Color(0xFFE4E4F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? cs.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
