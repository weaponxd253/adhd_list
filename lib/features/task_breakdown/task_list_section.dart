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
      padding: const EdgeInsets.all(8.0),
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
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (bool? value) {
                Provider.of<AppState>(context, listen: false)
                    .toggleTaskCompletion(index);
              },
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 18,
                decoration: task.status == "completed"
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
                "Due Date: ${task.dueDate.toLocal().toString().split(' ')[0]}"),
            
            // ADD EDIT AND DELETE BUTTONS HERE
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(context, task),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    Provider.of<AppState>(context, listen: false)
                        .deleteTask(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Task deleted")),
                    );
                  },
                ),
              ],
            ),

            children: [
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

    // ADD Edit & Delete Buttons
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _showEditSubtaskDialog(context, index, subtaskIndex, subtask.title),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            Provider.of<AppState>(context, listen: false)
                .deleteSubtask(index, subtaskIndex);
          },
        ),
      ],
    ),
  );
}).toList(),

              ),

              //  Subtask Input Section
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

  

void _showEditSubtaskDialog(BuildContext context, int taskIndex, int subtaskIndex, String currentTitle) {
  TextEditingController subtaskController = TextEditingController(text: currentTitle);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Edit Subtask"),
        content: TextField(
          controller: subtaskController,
          decoration: InputDecoration(labelText: "Subtask Title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppState>(context, listen: false)
                  .editSubtask(taskIndex, subtaskIndex, subtaskController.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      );
    },
  );
}


  /// Show a dialog to edit the task title and due date
  void _showEditDialog(BuildContext context, Task task) {
    TextEditingController titleController =
        TextEditingController(text: task.title);
    DateTime selectedDate = task.dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Task Title"),
              ),
              SizedBox(height: 10),
              Text("Due Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
              TextButton(
                child: Text("Change Date"),
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Provider.of<AppState>(context, listen: false)
                    .editTask(task.id, titleController.text, selectedDate);
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
