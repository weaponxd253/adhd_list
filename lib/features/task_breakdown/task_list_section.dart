import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/task.dart';
import '../../models/subtask.dart';

class TaskListSection extends StatefulWidget {
  final List<Task> tasks;
  const TaskListSection({super.key, required this.tasks});

  @override
  _TaskListSectionState createState() => _TaskListSectionState();
}

class _TaskListSectionState extends State<TaskListSection> {
  // Keyed by task.id so controllers survive list reorders and deletions.
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    for (final f in _focusNodes.values) f.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(int taskId) {
    return _controllers.putIfAbsent(taskId, () => TextEditingController());
  }

  FocusNode _focusNodeFor(int taskId) {
    return _focusNodes.putIfAbsent(taskId, () => FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        final subtaskController = _controllerFor(task.id);
        final focusNode = _focusNodeFor(task.id);

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (_) {
                Provider.of<AppState>(context, listen: false)
                    .toggleTaskCompletion(index);
              },
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 18,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
                "Due: ${task.dueDate.toLocal().toString().split(' ')[0]}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(context, task),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    Provider.of<AppState>(context, listen: false)
                        .deleteTask(task.id);
                    // Clean up the controller and focus node for this task
                    _controllers.remove(task.id)?.dispose();
                    _focusNodes.remove(task.id)?.dispose();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Task deleted")),
                    );
                  },
                ),
              ],
            ),
            children: [
              // Subtask list
              ...task.subtasks.asMap().entries.map((entry) {
                final subtaskIndex = entry.key;
                final subtask = entry.value;
                return ListTile(
                  leading: Checkbox(
                    value: subtask.isCompleted,
                    onChanged: (_) {
                      Provider.of<AppState>(context, listen: false)
                          .toggleSubtaskCompletion(index, subtaskIndex);
                    },
                  ),
                  title: Text(
                    subtask.title,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: subtask.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditSubtaskDialog(
                            context, index, subtaskIndex, subtask.title),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          Provider.of<AppState>(context, listen: false)
                              .deleteSubtask(index, subtaskIndex);
                        },
                      ),
                    ],
                  ),
                );
              }),

              // Subtask input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subtaskController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: "Add subtask",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.blueAccent),
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

  void _showEditSubtaskDialog(
      BuildContext context, int taskIndex, int subtaskIndex, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Subtask"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Subtask title"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Provider.of<AppState>(context, listen: false)
                  .editSubtask(taskIndex, subtaskIndex, controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Task task) {
    final titleController = TextEditingController(text: task.title);
    DateTime selectedDate = task.dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Edit Task"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(labelText: "Task title"),
                ),
                const SizedBox(height: 10),
                Text(
                    "Due: ${selectedDate.toLocal().toString().split(' ')[0]}"),
                TextButton(
                  child: const Text("Change Date"),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  Provider.of<AppState>(context, listen: false)
                      .editTask(task.id, titleController.text, selectedDate);
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }
}
