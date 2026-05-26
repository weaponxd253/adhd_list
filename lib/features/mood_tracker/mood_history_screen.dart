import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

// Refactored to read from AppState.moodHistoryList instead of querying
// MoodDatabase directly. This keeps it consistent with the rest of the app
// and means it automatically reflects any mood logged in the same session.
class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final history = appState.moodHistoryList;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Mood History"),
          ),
          body: history.isEmpty
              ? const Center(child: Text("No mood history yet."))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final rawDate = entry['date'] as String;
                    final datePart = rawDate.split('T')[0];

                    return ListTile(
                      leading: Text(
                        entry['emoji'] as String? ?? '😊',
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        entry['mood'] as String? ?? 'Unknown mood',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Date: $datePart"),
                    );
                  },
                ),
        );
      },
    );
  }
}