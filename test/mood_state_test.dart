import 'package:adhd_list/providers/mood_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('MoodState', () {
    test('loads the latest mood and history', () async {
      final repository = FakeMoodRepository(entries: [
        {
          'id': 2,
          'mood': 'Calm',
          'emoji': '🙂',
          'date': '2026-06-23T12:00:00.000',
        },
        {
          'id': 1,
          'mood': 'Sad',
          'emoji': '🙁',
          'date': '2026-06-22T12:00:00.000',
        },
      ]);
      final state = MoodState(repository: repository, autoLoad: false);
      await state.load();

      expect(state.selectedMood, 'Calm');
      expect(state.selectedMoodEmoji, '🙂');
      expect(state.moodHistoryList, hasLength(2));
    });

    test('saves and clears mood state', () async {
      final repository = FakeMoodRepository();
      final state = MoodState(repository: repository, autoLoad: false);

      await state.setMood('Hopeful', '🌱');
      expect(state.selectedMood, 'Hopeful');
      expect(state.moodHistoryList, hasLength(1));

      await state.clearMoodHistory();
      expect(state.selectedMood, isEmpty);
      expect(state.selectedMoodEmoji, isEmpty);
      expect(state.moodHistoryList, isEmpty);
    });

    test('failed save preserves the current selection', () async {
      final repository = FakeMoodRepository(entries: [
        {
          'id': 1,
          'mood': 'Calm',
          'emoji': '🙂',
          'date': '2026-06-23T12:00:00.000',
        },
      ]);
      final state = MoodState(repository: repository, autoLoad: false);
      await state.load();
      repository.failWrites = true;

      await expectLater(state.setMood('Sad', '🙁'), throwsStateError);
      expect(state.selectedMood, 'Calm');
      expect(state.selectedMoodEmoji, '🙂');
    });
  });
}
