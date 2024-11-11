// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'FocusFlow',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: HomeScreen(), // Set HomeScreen as the entry point
      ),
    );
  }
}
