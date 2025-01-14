// lib/features/task_breakdown/task_list_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class TaskListSection extends StatefulWidget {
  @override
  _TaskListSectionState createState() => _TaskListSectionState();
}

class _TaskListSectionState extends State<TaskListSection> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((focusNode) => focusNode.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: appState.tasks.length,
      itemBuilder: (context, index) {
        final task = appState.tasks[index];

        // Initialize controllers and focus nodes if not already done
        if (!_controllers.containsKey(index)) {
          _controllers[index] = TextEditingController();
        }
        if (!_focusNodes.containsKey(index)) {
          _focusNodes[index] = FocusNode();
        }

        final subtaskController = _controllers[index]!;
        final focusNode = _focusNodes[index]!;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (_) {
                appState.toggleTaskCompletion(index);
              },
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 18,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text("Due Date: ${task.dueDate.toLocal().toString().split(' ')[0]}"),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subtaskController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: "Enter Subtask",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.blueAccent),
                          onPressed: () {
                            final text = subtaskController.text.trim();
                            if (text.isNotEmpty) {
                              appState.addSubtask(index, text);
                              subtaskController.clear();
                              focusNode.unfocus(); // Prevents unnecessary focus retention
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: task.subtasks.length,
                      itemBuilder: (context, subIndex) {
                        final subtask = task.subtasks[subIndex];
                        return ListTile(
                          title: Text(
                            "- ${subtask.title}",
                            style: TextStyle(
                              fontSize: 16,
                              color: subtask.isCompleted ? Colors.grey : Colors.black,
                              decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          leading: Checkbox(
                            value: subtask.isCompleted,
                            onChanged: (value) {
                              appState.toggleSubtaskCompletion(index, subIndex);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: appState.tasks.length,
      itemBuilder: (context, index) {
        final task = appState.tasks[index];
        final TextEditingController subtaskController = TextEditingController();

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (_) {
                appState.toggleTaskCompletion(index);
              },
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 18,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text("Due Date: ${task.dueDate.toLocal().toString().split(' ')[0]}"),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Subtask Input Section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subtaskController,
                            decoration: InputDecoration(
                              labelText: "Enter Subtask",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.blueAccent),
                          onPressed: () {
                            final text = subtaskController.text.trim();
                            if (text.isNotEmpty) {
                              appState.addSubtask(index, text);
                              subtaskController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Subtask List Section
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: task.subtasks.length,
                      itemBuilder: (context, subIndex) {
                        final subtask = task.subtasks[subIndex];
                        return ListTile(
                          title: Text(
                            "- ${subtask.title}",
                            style: TextStyle(
                              fontSize: 16,
                              color: subtask.isCompleted ? Colors.grey : Colors.black,
                              decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          leading: Checkbox(
                            value: subtask.isCompleted,
                            onChanged: (value) {
                              appState.toggleSubtaskCompletion(index, subIndex);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

