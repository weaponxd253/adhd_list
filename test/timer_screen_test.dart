import 'package:adhd_list/features/timer/timer_screen.dart';
import 'package:adhd_list/providers/timer_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> _pumpTimerScreen(
  WidgetTester tester,
  TimerState state,
) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(state.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const TimerScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows timer status and completion feedback', (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final state = TimerState(now: () => now)
      ..updateDurations(focus: 1, shortBreak: 5, longBreak: 15);
    await _pumpTimerScreen(tester, state);

    expect(find.text('Ready to start'), findsOneWidget);

    state.startTimer();
    await tester.pump();
    expect(find.text('Session in progress'), findsOneWidget);

    now = startedAt.add(const Duration(minutes: 1));
    state.syncWithClock();
    await tester.pump();
    await tester.pump();

    expect(find.text('Short Break ready'), findsOneWidget);
    expect(find.text('Focus complete. Short Break ready.'), findsOneWidget);
  });

  testWidgets('reconciles completed sessions when the app resumes',
      (tester) async {
    final startedAt = DateTime(2026, 6, 23, 9);
    var now = startedAt;
    final state = TimerState(now: () => now)
      ..updateDurations(focus: 1, shortBreak: 5, longBreak: 15);
    await _pumpTimerScreen(tester, state);

    state.startTimer();
    await tester.pump();

    now = startedAt.add(const Duration(seconds: 75));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(find.text('Short Break ready'), findsOneWidget);
    expect(find.text('Focus complete. Short Break ready.'), findsOneWidget);
  });
}
