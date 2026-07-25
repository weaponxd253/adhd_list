import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_state.dart';
import 'task_input_section.dart';
import 'task_list_section.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late final TextEditingController _taskController;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Column(
        children: [
          TaskInputSection(taskController: _taskController),
          Expanded(
            child: Consumer<TaskState>(
              builder: (context, taskState, _) {
                if (taskState.isLoading && taskState.tasks.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading tasks',
                    ),
                  );
                }
                return TaskListSection(taskState: taskState);
              },
            ),
          ),
        ],
      ),
    );
  }
}
