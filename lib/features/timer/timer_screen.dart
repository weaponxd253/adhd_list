import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final List<String> _modes = ["Focus", "Short Break", "Long Break"];
  final List<IconData> _modeIcons = [Icons.work, Icons.coffee, Icons.bed];
  final List<Color> _modeColors = [Colors.green, Colors.blue, Colors.orange];

  // Initialised from AppState so switching tabs doesn't reset the mode display.
  late int _selectedModeIndex;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final idx = _modes.indexOf(appState.currentMode);
    _selectedModeIndex = idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pomodoro Timer"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildModeSelector(appState),
              const SizedBox(height: 30),
              _buildTimerDisplay(appState),
              const SizedBox(height: 30),
              _buildTimerControls(appState),
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
        const Text(
          "Select Mode",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ToggleButtons(
          isSelected: List.generate(3, (index) => index == _selectedModeIndex),
          onPressed: (index) {
            setState(() {
              _selectedModeIndex = index;
            });
            appState.setMode(_modes[index]);
            appState.updateTimerDuration(_modes[index]);
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
                  const SizedBox(height: 4),
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
        const SizedBox(height: 10),
        CircularProgressIndicator(
          value: appState.progress,
          strokeWidth: 8,
          color: _modeColors[_selectedModeIndex],
        ),
      ],
    );
  }

  // ----------------------------------------
  // Enhanced Timer Controls
  // ----------------------------------------
  Widget _buildTimerControls(AppState appState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: appState.isTimerRunning
              ? null
              : () => appState.startTimer(_modes[_selectedModeIndex] == "Focus"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _modeColors[_selectedModeIndex],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: Text(appState.isTimerRunning ? "Running" : "Start"),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: appState.isTimerRunning ? appState.pauseTimer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: const Text("Pause"),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: appState.resetTimer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: const Text("Reset"),
        ),
      ],
    );
  }
}