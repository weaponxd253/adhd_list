// lib/features/hyperfocus/hyperfocus_screen.dart
import 'package:flutter/material.dart';

class HyperfocusScreen extends StatelessWidget {
  const HyperfocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hyperfocus Mode")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Background Sound"),
          const SoundOptions(),
          const SizedBox(height: 20),
          const Text("Focus Time"),
          const FocusTimeSlider(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Start Focus Mode"),
          ),
        ],
      ),
    );
  }
}

class SoundOptions extends StatelessWidget {
  const SoundOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      items: ["White Noise", "Lo-fi Beats", "Nature Sounds"].map((sound) {
        return DropdownMenuItem(value: sound, child: Text(sound));
      }).toList(),
      onChanged: (value) {},
      hint: const Text("Choose Background Sound"),
    );
  }
}

class FocusTimeSlider extends StatelessWidget {
  const FocusTimeSlider({super.key});

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
