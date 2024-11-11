// lib/features/task_breakdown/task_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

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
          TaskInputSection(taskController: taskController),
          Expanded(child: TaskListSection()),
        ],
      ),
    );
  }
}

class TaskInputSection extends StatelessWidget {
  final TextEditingController taskController;

  TaskInputSection({required this.taskController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: taskController,
            decoration: InputDecoration(
              labelText: "Enter Task",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              if (taskController.text.isNotEmpty) {
                Provider.of<AppState>(context, listen: false)
                    .addTask(taskController.text);
                taskController.clear();
              }
            },
            icon: Icon(Icons.add),
            label: Text("Add Task"),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: appState.tasks.length,
      itemBuilder: (context, index) {
        final task = appState.tasks[index];
        double progress = task.subtasks.isEmpty
            ? 0
            : task.subtasks.where((subtask) => subtask.isCompleted).length / task.subtasks.length;

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
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blueAccent,
                      minHeight: 8,
                    ),
                    SizedBox(height: 10),
                    SubtaskInputSection(taskIndex: index),
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
                              color: subtask.isCompleted
                                  ? Colors.grey
                                  : Colors.black,
                              decoration: subtask.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
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

class SubtaskInputSection extends StatelessWidget {
  final int taskIndex;
  final TextEditingController subtaskController = TextEditingController();

  SubtaskInputSection({required this.taskIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            if (subtaskController.text.isNotEmpty) {
              Provider.of<AppState>(context, listen: false)
                  .addSubtask(taskIndex, subtaskController.text);
              subtaskController.clear();
            }
          },
        ),
      ],
    );
  }
}
