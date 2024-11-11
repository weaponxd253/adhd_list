// lib/features/timer/timer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class TimerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final minutes = (appState.remainingTime / 60).floor();
    final seconds = (appState.remainingTime % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: Text("Pomodoro Timer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Timer: $minutes:$seconds", style: TextStyle(fontSize: 32)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (!appState.isTimerRunning) {
                      appState.startTimer(true); // Start work session
                    }
                  },
                  icon: Icon(Icons.play_arrow),
                ),
                IconButton(
                  onPressed: () {
                    appState.pauseTimer(); // Pause timer
                  },
                  icon: Icon(Icons.pause),
                ),
                IconButton(
                  onPressed: () {
                    appState.stopTimer(); // Stop timer
                  },
                  icon: Icon(Icons.stop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
