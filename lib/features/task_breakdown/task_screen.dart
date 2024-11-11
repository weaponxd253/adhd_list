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
      appBar: AppBar(
        title: Text("Task Breakdown"),
      ),
      body: Column(
        children: [
          TaskInputSection(taskController: taskController), // Task input section for adding tasks
          Expanded(child: TaskListSection()), // Task list section for viewing tasks
        ],
      ),
    );
  }
}
