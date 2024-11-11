// lib/features/tracker/mood_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class MoodHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final moodHistory = appState.moodHistory; // Assuming moodHistory is stored in AppState

    return Scaffold(
      appBar: AppBar(
        title: Text("Mood History"),
      ),
      body: ListView.builder(
        itemCount: moodHistory.length,
        itemBuilder: (context, index) {
          final moodEntry = moodHistory[index];
          return ListTile(
            leading: Text(
              moodEntry['emoji'] ?? '😊', // Provide a default emoji if null
              style: TextStyle(fontSize: 24),
            ),
            title: Text(
              moodEntry['mood'] ?? 'Unknown mood', // Default text if null
            ),
            subtitle: Text(
              "Date: ${moodEntry['date'] ?? 'Unknown date'}", // Default text if null
            ),
          );
        },
      ),
    );
  }
}
