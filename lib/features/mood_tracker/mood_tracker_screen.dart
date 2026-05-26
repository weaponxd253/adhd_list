import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../mood_tracker/mood_history_screen.dart';

class MoodTrackerScreen extends StatelessWidget {
  const MoodTrackerScreen({super.key});

  static const List<Map<String, String>> _moodOptions = [
    {"emoji": "🌱", "label": "Hopeful"},
    {"emoji": "⚠️", "label": "Triggered"},
    {"emoji": "🧘", "label": "Calm"},
    {"emoji": "🧠", "label": "Mindful"},
    {"emoji": "✊", "label": "Empowered"},
    {"emoji": "💧", "label": "Vulnerable"},
    {"emoji": "🤗", "label": "Validated"},
    {"emoji": "🌍", "label": "Grounded"},
    {"emoji": "❄️", "label": "Disconnected"},
    {"emoji": "🌞", "label": "Optimistic"},
    {"emoji": "🌀", "label": "Distracted"},
    {"emoji": "🖤", "label": "Grieving"},
    {"emoji": "🚫", "label": "Rejected"},
    {"emoji": "💖", "label": "Accepted"},
    {"emoji": "🔥", "label": "Burnt Out"},
    {"emoji": "💬", "label": "Encouraged"},
    {"emoji": "✨", "label": "Inspired"},
    {"emoji": "😌", "label": "Relaxed"},
    {"emoji": "😃", "label": "Joyful"},
    {"emoji": "😔", "label": "Sad"},
    {"emoji": "😤", "label": "Frustrated"},
    {"emoji": "😨", "label": "Anxious"},
    {"emoji": "🤩", "label": "Excited"},
    {"emoji": "😡", "label": "Angry"},
    {"emoji": "😟", "label": "Worried"},
    {"emoji": "🍀", "label": "Grateful"},
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Mood Tracker"),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Mood History',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MoodHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "How are you feeling today?",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Mood picker
                Expanded(
                  child: ListView.builder(
                    itemCount: _moodOptions.length,
                    itemBuilder: (context, index) {
                      final mood = _moodOptions[index];
                      final isSelected =
                          appState.selectedMood == mood["label"];
                      return GestureDetector(
                        onTap: () {
                          appState.setMood(mood["label"]!, mood["emoji"]!);
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context, true);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue[100]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(mood["emoji"]!,
                                  style: const TextStyle(fontSize: 30)),
                              const SizedBox(width: 10),
                              Text(
                                mood["label"]!,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (appState.selectedMood.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      "Selected Mood: ${appState.selectedMoodEmoji} ${appState.selectedMood}",
                      style: const TextStyle(
                          fontSize: 18, color: Colors.blueAccent),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}