import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../database/mood_database.dart';
import '../repositories/repositories.dart';

class MoodState extends ChangeNotifier {
  MoodState({
    MoodRepository? repository,
    bool autoLoad = true,
  }) : _repository = repository ?? MoodDatabase.instance {
    if (autoLoad) unawaited(load());
  }

  final MoodRepository _repository;

  String _selectedMood = '';
  String _selectedMoodEmoji = '';
  List<Map<String, dynamic>> _history = [];

  String get selectedMood => _selectedMood;
  String get selectedMoodEmoji => _selectedMoodEmoji;
  UnmodifiableListView<Map<String, dynamic>> get moodHistoryList =>
      UnmodifiableListView(_history);

  static const _messages = <String, String>{
    'Hopeful': 'Think of one small step you can take toward your goal today.',
    'Calm': 'Take a moment to enjoy this peace and what helped create it.',
    'Optimistic': 'Carry this outlook into one useful action.',
    'Joyful': 'Savor this positive energy and share it if you can.',
    'Excited': 'Channel that energy into something meaningful.',
    'Inspired': 'Capture the idea and take one small first step.',
    'Empowered': 'Use this energy to move one important thing forward.',
    'Grateful': 'Notice the small things you appreciate right now.',
    'Relaxed': 'Let yourself unwind and recharge.',
    'Mindful': 'Notice your body, breath, and surroundings.',
    'Grounded': 'Focus on something steady and present around you.',
    'Validated': 'Take a moment to appreciate feeling seen.',
    'Encouraged': 'Keep this support close as you take your next step.',
    'Accepted': 'Celebrate who you are and how far you have come.',
    'Sad': 'Give yourself time and gentleness while this feeling passes.',
    'Worried': 'Focus on what you can control right now.',
    'Anxious': 'Try slow breaths and bring attention to the present.',
    'Frustrated': 'Pause, reset, and approach one small part afresh.',
    'Angry': 'Pause before acting and choose a constructive outlet.',
    'Vulnerable': 'It is okay to lean on someone you trust.',
    'Disconnected': 'Try one small act of connection or comfort.',
    'Distracted': 'Choose one tiny task and give it five minutes.',
    'Burnt Out': 'Rest is productive when your system needs recovery.',
    'Triggered': 'Breathe slowly and name what you can see and feel.',
    'Rejected': 'This moment does not define your worth.',
    'Grieving': 'Give yourself grace and reach for support when needed.',
  };

  String get moodMessage =>
      _messages[_selectedMood] ?? 'Notice what you need in this moment.';

  Future<void> load() async {
    final lastMood = await _repository.fetchLastMood();
    _history = await _repository.fetchMoods();
    if (lastMood != null) {
      _selectedMood = lastMood['mood'] as String;
      _selectedMoodEmoji = lastMood['emoji'] as String;
    }
    notifyListeners();
  }

  Future<void> setMood(String mood, String emoji) async {
    await _repository.insertMood(mood, emoji);
    _selectedMood = mood;
    _selectedMoodEmoji = emoji;
    _history = await _repository.fetchMoods();
    notifyListeners();
  }

  Future<void> clearMoodHistory() async {
    await _repository.clearMoods();
    _history = [];
    _selectedMood = '';
    _selectedMoodEmoji = '';
    notifyListeners();
  }
}
