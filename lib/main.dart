// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart'; // App-wide state
import 'features/task_breakdown/task_screen.dart'; // Import features
import 'features/dashboard/dashboard_screen.dart';
import 'features/hyperfocus/hyperfocus_screen.dart';

void main() {
  runApp(FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()), // Global app state
        // Additional providers for individual features
      ],
      child: MaterialApp(
        title: 'FocusFlow',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: DashboardScreen(), // Main entry screen
        routes: {
          '/tasks': (_) => TaskScreen(),
          '/hyperfocus': (_) => HyperfocusScreen(),
          // Other routes
        },
      ),
    );
  }
}
