// lib/features/mood_tracker/mood_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class MoodTrackerScreen extends StatefulWidget {
  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  String selectedMood = '';

  final List<Map<String, String>> moodOptions = [
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
    {"emoji": "🌌", "label": "Lonely"},
    {"emoji": "🔥", "label": "Burnt Out"},
    {"emoji": "🛡️", "label": "Resilient"},
    {"emoji": "🔆", "label": "Centered"},
    {"emoji": "🫣", "label": "Panicked"},
    {"emoji": "💬", "label": "Encouraged"},
    {"emoji": "✨", "label": "Inspired"},
    {"emoji": "🛌", "label": "Exhausted"},
    {"emoji": "☺️", "label": "Content"},
    {"emoji": "🌩️", "label": "Irritable"},
    {"emoji": "👥", "label": "Supported"},
  ];

void _selectMood(String moodLabel, String moodEmoji) {
  setState(() {
    selectedMood = moodLabel;
  });

  // Save the selected mood and emoji to AppState
  Provider.of<AppState>(context, listen: false).setMood(moodLabel, moodEmoji);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mood Tracker"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "How are you feeling today?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: moodOptions.length,
                itemBuilder: (context, index) {
                  final mood = moodOptions[index];
                  final isSelected = selectedMood == mood["label"];

                  return GestureDetector(
                    onTap: () => _selectMood(mood["label"]!, mood["emoji"]!),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.blueAccent : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            mood["emoji"]!,
                            style: TextStyle(fontSize: 30),
                          ),
                          SizedBox(width: 10),
                          Text(
                            mood["label"]!,
                            style: TextStyle(
                              fontSize: 18,
                              color: isSelected ? Colors.blueAccent : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (selectedMood.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  "Selected Mood: $selectedMood",
                  style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
