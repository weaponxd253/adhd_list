import 'dart:ui' show SemanticsFlag;

import 'package:adhd_list/features/mood_tracker/mood_tracker_screen.dart';
import 'package:adhd_list/providers/mood_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

Future<void> _pumpMoodTracker(
  WidgetTester tester,
  MoodState state, {
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  addTearDown(state.dispose);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MoodTrackerScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('mood choices expose semantic selection state', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final state = MoodState(
        repository: FakeMoodRepository(),
        autoLoad: false,
      );

      await _pumpMoodTracker(tester, state);

      final calmFinder = find.bySemanticsLabel('Select Calm mood');
      expect(calmFinder, findsOneWidget);
      expect(
        tester.getSemantics(calmFinder).hasFlag(SemanticsFlag.isButton),
        isTrue,
      );

      await tester.tap(find.text('Calm'));
      await tester.pump();

      expect(
        tester.getSemantics(calmFinder).hasFlag(SemanticsFlag.isSelected),
        isTrue,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('mood screen supports large text without overflow',
      (tester) async {
    final state = MoodState(
      repository: FakeMoodRepository(),
      autoLoad: false,
    );

    await _pumpMoodTracker(
      tester,
      state,
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
  });
}
