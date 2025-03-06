import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../database/task_database.dart';
import '../../models/task.dart';
import '../../models/subtask.dart'; 


class TaskListSection extends StatefulWidget {
  final List<Task> tasks;
  TaskListSection({required this.tasks});

  @override
  _TaskListSectionState createState() => _TaskListSectionState();
}

class _TaskListSectionState extends State<TaskListSection> {
  final TaskDatabase taskDb = TaskDatabase();
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final task = widget.tasks[index];

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
              value: task.status == "completed", // ✅ Fix: Use status instead of isCompleted
              onChanged: (value) {
                String newStatus = value! ? "completed" : "pending";
                Provider.of<AppState>(context, listen: false)
                    .updateTaskStatus(task.id, newStatus);
              },
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 18,
                decoration: task.status == "completed" ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text("Due Date: ${task.dueDate.toLocal().toString().split(' ')[0]}"),
            children: [
              // ✅ Display Subtasks
              Column(
                children: (task.subtasks ?? []).asMap().entries.map((entry) {
                  int subtaskIndex = entry.key;
                  Subtask subtask = entry.value;

                  return ListTile(
                    leading: Checkbox(
                      value: subtask.isCompleted,
                      onChanged: (value) {
                        Provider.of<AppState>(context, listen: false)
                            .toggleSubtaskCompletion(index, subtaskIndex);
                      },
                    ),
                    title: Text(
                      subtask.title,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // ✅ Subtask Input Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subtaskController,
                        decoration: InputDecoration(
                          labelText: "Enter Subtask",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                          Provider.of<AppState>(context, listen: false)
                              .addSubtask(index, text);
                          subtaskController.clear();
                          focusNode.unfocus();
                        }
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
