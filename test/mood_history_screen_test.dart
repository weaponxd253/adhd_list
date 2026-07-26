import 'package:adhd_list/features/mood_tracker/mood_history_screen.dart';
import 'package:adhd_list/providers/mood_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

Future<void> _pumpMoodHistory(
  WidgetTester tester,
  MoodState state,
) async {
  await state.load();
  addTearDown(state.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const MoodHistoryScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows an empty mood history state', (tester) async {
    final state = MoodState(
      repository: FakeMoodRepository(),
      autoLoad: false,
    );

    await _pumpMoodHistory(tester, state);

    expect(find.text('No mood history yet'), findsOneWidget);
  });

  testWidgets('groups mood history by formatted day', (tester) async {
    final state = MoodState(
      repository: FakeMoodRepository(
        entries: [
          {
            'mood': 'Relaxed',
            'emoji': '\u{1F60C}',
            'date': DateTime(2026, 6, 22, 9, 30).toIso8601String(),
          },
          {
            'mood': 'Mindful',
            'emoji': '\u{1F9E0}',
            'date': DateTime(2026, 5, 25, 16, 5).toIso8601String(),
          },
          {
            'mood': 'Grounded',
            'emoji': '\u{1F30D}',
            'date': DateTime(2026, 5, 25, 8).toIso8601String(),
          },
        ],
      ),
      autoLoad: false,
    );

    await _pumpMoodHistory(tester, state);

    expect(find.text('June 22, 2026'), findsOneWidget);
    expect(find.text('May 25, 2026'), findsOneWidget);
    expect(find.text('Relaxed'), findsOneWidget);
    expect(find.text('Mindful'), findsOneWidget);
    expect(find.text('Grounded'), findsOneWidget);
  });
}
