import 'package:adhd_list/features/timer/timer_history_screen.dart';
import 'package:adhd_list/providers/timer_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

Future<void> _pumpTimerHistory(
  WidgetTester tester,
  TimerState state,
) async {
  addTearDown(state.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const TimerHistoryScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows empty timer history state', (tester) async {
    final state = TimerState(
      sessionRepository: FakeTimerSessionRepository(),
    );

    await _pumpTimerHistory(tester, state);

    expect(find.text('No timer sessions yet'), findsOneWidget);
  });

  testWidgets('shows grouped timer sessions', (tester) async {
    final state = TimerState(
      sessionRepository: FakeTimerSessionRepository(
        sessions: [
          {
            'id': 1,
            'mode': 'Focus',
            'started_at': DateTime(2026, 6, 23, 9).toIso8601String(),
            'ended_at': DateTime(2026, 6, 23, 9, 25).toIso8601String(),
            'duration_seconds': 1500,
            'completed': 1,
            'task_id': 42,
            'subtask_id': 77,
            'target_type': TimerState.targetTypeSubtask,
            'target_title_snapshot': 'Find one source',
            'outcome': TimerState.outcomeLeftOpen,
          },
          {
            'id': 2,
            'mode': 'Long Break',
            'started_at': DateTime(2026, 6, 22, 12).toIso8601String(),
            'ended_at': DateTime(2026, 6, 22, 12, 15).toIso8601String(),
            'duration_seconds': 900,
            'completed': 1,
          },
        ],
      ),
    );

    await _pumpTimerHistory(tester, state);

    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Long Break'), findsOneWidget);
    expect(find.text('Step: Find one source'), findsOneWidget);
    expect(find.textContaining('Left open'), findsOneWidget);
    expect(find.textContaining('25 min'), findsOneWidget);
    expect(find.textContaining('15 min'), findsOneWidget);
  });
}
