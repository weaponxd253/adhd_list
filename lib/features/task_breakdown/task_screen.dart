// lib/features/task_breakdown/task_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class TaskScreen extends StatelessWidget {
  final TextEditingController taskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Task Breakdown")),
      body: Column(
        children: [
          TaskInputSection(controller: taskController),
          Expanded(child: TaskListSection()),
          PomodoroTimerSection(),
        ],
      ),
    );
  }
}

class TaskInputSection extends StatelessWidget {
  final TextEditingController controller;

  TaskInputSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(labelText: "Enter Task"),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<AppState>(context, listen: false)
                    .addTask(controller.text);
                controller.clear(); // Clear the input after adding the task
              }
            },
            child: Text("Add Task"),
          ),
        ],
      ),
    );
  }
}

class TaskListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<AppState>(context).tasks; // Get tasks from AppState

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(tasks[index]),
          leading: IconButton(
            icon: Icon(Icons.check_box_outline_blank),
            onPressed: () {
              Provider.of<AppState>(context, listen: false)
                  .removeTask(tasks[index]); // Remove task on tap
            },
          ),
        );
      },
    );
  }
}

class PomodoroTimerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Pomodoro Timer: 25:00"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: () {}, icon: Icon(Icons.play_arrow)),
            IconButton(onPressed: () {}, icon: Icon(Icons.pause)),
            IconButton(onPressed: () {}, icon: Icon(Icons.stop)),
          ],
        ),
      ],
    );
  }
}
