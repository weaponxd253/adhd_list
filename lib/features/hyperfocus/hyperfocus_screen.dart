// lib/features/hyperfocus/hyperfocus_screen.dart
import 'package:flutter/material.dart';

class HyperfocusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hyperfocus Mode")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Background Sound"),
          SoundOptions(),
          SizedBox(height: 20),
          Text("Focus Time"),
          FocusTimeSlider(),
          SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, child: Text("Start Focus Mode")),
        ],
      ),
    );
  }
}

class SoundOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      items: ["White Noise", "Lo-fi Beats", "Nature Sounds"].map((sound) {
        return DropdownMenuItem(child: Text(sound), value: sound);
      }).toList(),
      onChanged: (value) {},
      hint: Text("Choose Background Sound"),
    );
  }
}

class FocusTimeSlider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Slider(
      value: 30,
      min: 15,
      max: 120,
      divisions: 7,
      label: "30 mins",
      onChanged: (value) {},
    );
  }
}
