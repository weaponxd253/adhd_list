import 'package:flutter/material.dart';
import '../../database/task_database.dart';

class TaskListSection extends StatefulWidget {
  @override
  _TaskListSectionState createState() => _TaskListSectionState();
}

class _TaskListSectionState extends State<TaskListSection> {
  final TaskDatabase taskDb = TaskDatabase();
  List<Map<String, dynamic>> _tasks = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await taskDb.fetchTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _toggleTaskCompletion(int id, bool isCompleted) async {
    await taskDb.updateTask(id, isCompleted ? 1 : 0);
    _loadTasks(); // Refresh tasks after update
  }

  Future<void> _addSubtask(int taskId, String subtaskTitle) async {
    // This assumes you have a subtask table, you need to implement its database logic separately
    // await taskDb.insertSubtask(taskId, subtaskTitle);
    _loadTasks(); // Refresh tasks after adding subtask
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((focusNode) => focusNode.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];

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
              value: task['is_completed'] == 1,
              onChanged: (value) {
                _toggleTaskCompletion(task['id'], value!);
              },
            ),
            title: Text(
              task['title'],
              style: TextStyle(
                fontSize: 18,
                decoration: task['is_completed'] == 1 ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text("Due Date: ${task['due_date']}"),
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
                              _addSubtask(task['id'], text);
                              subtaskController.clear();
                              focusNode.unfocus();
                            }
                          },
                        ),
                      ],
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
