import 'package:adhd_list/providers/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/mood_database.dart';

class MoodTrackerScreen extends StatefulWidget {
  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final MoodDatabase moodDb = MoodDatabase.instance;
  String selectedMood = '';
  List<Map<String, dynamic>> moodHistory = [];

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
  void initState() {
    super.initState();
     Provider.of<AppState>(context, listen: false).loadLastMood();
      _loadMoodHistory();
  }

  Future<void> _loadMoodHistory() async {
    final moods = await moodDb.fetchMoods();
    setState(() {
      moodHistory = moods;
    });
  }

void _selectMood(String moodLabel, String moodEmoji) async {
  Provider.of<AppState>(context, listen: false).setMood(moodLabel, moodEmoji);
  
  // Pop the screen and send a signal to refresh the dashboard
  Navigator.pop(context, true);
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
            const Text(
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
            SizedBox(height: 20),
            const Text(
              "Mood History",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: moodHistory.length,
                itemBuilder: (context, index) {
                  final moodEntry = moodHistory[index];
                  return ListTile(
                    leading: Text(
                      moodEntry['emoji'],
                      style: TextStyle(fontSize: 30),
                    ),
                    title: Text(moodEntry['mood']),
                    subtitle: Text("Date: ${moodEntry['date'].split('T')[0]}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
