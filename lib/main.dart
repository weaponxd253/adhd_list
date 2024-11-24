// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'features/home/home_screen.dart';

// Define light and dark themes
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  appBarTheme: AppBarTheme(color: Colors.blue),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.grey[900],
  appBarTheme: AppBarTheme(color: Colors.black),
);

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
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return AnimatedTheme(
            data: appState.themeMode == ThemeMode.light ? lightTheme : darkTheme,
            duration: Duration(milliseconds: 300), // Smooth transition duration
            curve: Curves.easeInOut, // Customizable animation curve
            child: MaterialApp(
              title: 'FocusFlow',
              theme: lightTheme, // Light theme
              darkTheme: darkTheme, // Dark theme
              themeMode: appState.themeMode, // Dynamically switch themes
              home: HomeScreen(), // Set HomeScreen as the entry point
            ),
          );
        },
      ),
    );
  }
}
