import 'package:flutter/material.dart';
import '../../database/mood_database.dart';

class MoodHistoryScreen extends StatefulWidget {
  @override
  _MoodHistoryScreenState createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  final MoodDatabase moodDb = MoodDatabase.instance;
  List<Map<String, dynamic>> _moodHistory = [];

  @override
  void initState() {
    super.initState();
    _loadMoodHistory();
  }

  Future<void> _loadMoodHistory() async {
    final moods = await moodDb.fetchMoods();
    setState(() {
      _moodHistory = moods;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mood History"),
      ),
      body: _moodHistory.isEmpty
          ? Center(child: Text("No mood history yet."))
          : ListView.builder(
              itemCount: _moodHistory.length,
              itemBuilder: (context, index) {
                final moodEntry = _moodHistory[index];
                return ListTile(
                  leading: Text(
                    moodEntry['emoji'] ?? '😊',
                    style: TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    moodEntry['mood'] ?? 'Unknown mood',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Date: ${moodEntry['date'].split('T')[0]}",
                  ),
                );
              },
            ),
    );
  }
}
