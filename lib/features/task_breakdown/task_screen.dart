import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_state.dart';
import 'task_input_section.dart';
import 'task_list_section.dart';

// Changed to StatefulWidget so _taskController is properly disposed.
// The previous StatelessWidget version created a controller that was never
// disposed, leaking resources on every rebuild.
class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  _TaskScreenState createState() => _TaskScreenState();
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
      appBar: AppBar(title: const Text("Task Breakdown")),
      body: Column(
        children: [
          TaskInputSection(taskController: _taskController),
          Expanded(
            child: Consumer<TaskState>(
              builder: (context, taskState, child) {
                return TaskListSection(tasks: taskState.tasks);
              },
            ),
          ),
        ],
      ),
    );
  }
}
