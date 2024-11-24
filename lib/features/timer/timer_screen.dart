// lib/features/timer/timer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _selectedModeIndex = 0; // 0: Focus, 1: Short Break, 2: Long Break
  final List<String> _modes = ["Focus", "Short Break", "Long Break"];
  final List<IconData> _modeIcons = [Icons.work, Icons.coffee, Icons.bed];
  final List<Color> _modeColors = [Colors.green, Colors.blue, Colors.orange];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Pomodoro Timer"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
            children: [
              _buildModeSelector(appState),
              SizedBox(height: 30),
              _buildTimerDisplay(appState),
              SizedBox(height: 30),
              _buildTimerControlButton(appState),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------
  // Mode Selector Widget
  // ----------------------------------------
  Widget _buildModeSelector(AppState appState) {
    return Column(
      children: [
        Text(
          "Select Mode",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ToggleButtons(
          isSelected: List.generate(3, (index) => index == _selectedModeIndex),
          onPressed: (index) {
            setState(() {
              _selectedModeIndex = index;
              appState.setMode(_modes[index]); // Update mode in app state
              appState.updateTimerDuration(_modes[index]);
            });
          },
          borderRadius: BorderRadius.circular(8),
          selectedColor: Colors.white,
          fillColor: _modeColors[_selectedModeIndex],
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_modeIcons[index]),
                  SizedBox(height: 4),
                  Text(_modes[index]),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ----------------------------------------
  // Timer Display Widget
  // ----------------------------------------
  Widget _buildTimerDisplay(AppState appState) {
    return Column(
      children: [
        Text(
          appState.timerDisplay,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _modeColors[_selectedModeIndex],
          ),
        ),
        SizedBox(height: 10),
        CircularProgressIndicator(
          value: appState.progress,
          strokeWidth: 8,
          color: _modeColors[_selectedModeIndex],
        ),
      ],
    );
  }

  // ----------------------------------------
  // Timer Control Button Widget
  // ----------------------------------------
  Widget _buildTimerControlButton(AppState appState) {
    return ElevatedButton(
      onPressed: appState.isTimerRunning
          ? appState.stopTimer
          : () => appState.startTimer(_modes[_selectedModeIndex] == "Focus"),
      child: Text(appState.isTimerRunning ? "Stop Timer" : "Start Timer"),
      style: ElevatedButton.styleFrom(
        backgroundColor: _modeColors[_selectedModeIndex],
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: TextStyle(fontSize: 18),
      ),
    );
  }
}
