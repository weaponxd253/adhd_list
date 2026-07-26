import 'package:adhd_list/features/home/home_screen.dart';
import 'package:adhd_list/providers/mood_state.dart';
import 'package:adhd_list/providers/settings_state.dart';
import 'package:adhd_list/providers/task_state.dart';
import 'package:adhd_list/providers/timer_state.dart';
import 'package:adhd_list/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

Widget _testApp({ThemeData? theme}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => TaskState(
          repository: FakeTaskRepository(),
          autoLoad: false,
        ),
      ),
      ChangeNotifierProvider(create: (_) => TimerState()),
      ChangeNotifierProvider(
        create: (_) => MoodState(
          repository: FakeMoodRepository(),
          autoLoad: false,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => SettingsState(
          repository: FakeSettingsRepository(),
          autoLoad: false,
        ),
      ),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.light,
      home: const HomeScreen(),
    ),
  );
}

void main() {
  group('AppTheme', () {
    test('uses padded Material tap targets and readable navigation labels', () {
      expect(
        AppTheme.light.materialTapTargetSize,
        MaterialTapTargetSize.padded,
      );
      expect(
        AppTheme.dark.materialTapTargetSize,
        MaterialTapTargetSize.padded,
      );
      expect(
        AppTheme.light.navigationBarTheme.labelBehavior,
        NavigationDestinationLabelBehavior.alwaysShow,
      );
    });

    test('defines semantic colors for both themes', () {
      expect(
        AppTheme.light.extension<AppSemanticColors>(),
        isNotNull,
      );
      expect(
        AppTheme.dark.extension<AppSemanticColors>(),
        isNotNull,
      );
    });
  });

  testWidgets('primary navigation changes destinations', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());

    NavigationBar navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 0);
    expect(find.text('FocusFlow'), findsOneWidget);

    await tester.tap(find.byKey(const Key('navigation-tasks')));
    await tester.pump(const Duration(milliseconds: 300));

    navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 1);
    expect(find.widgetWithText(AppBar, 'Tasks'), findsOneWidget);

    await tester.tap(find.byKey(const Key('navigation-timer')));
    await tester.pump(const Duration(milliseconds: 300));

    navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 2);
    expect(find.text('Timer'), findsWidgets);
  });

  testWidgets('navigation remains usable with large text', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _testApp(),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Mood'), findsOneWidget);
  });
}
