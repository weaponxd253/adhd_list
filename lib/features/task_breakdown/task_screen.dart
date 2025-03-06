import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'task_input_section.dart';
import 'task_list_section.dart';

class TaskScreen extends StatelessWidget {
  final TextEditingController taskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Task Breakdown")),
      body: Column(
        children: [
          TaskInputSection(taskController: taskController),
          Expanded(
            child: Consumer<AppState>( // 👈 Add this to listen for changes
              builder: (context, appState, child) {
                return TaskListSection(tasks: appState.tasks); // Pass updated tasks
              },
            ),
          ),
        ],
      ),
    );
  }
}

