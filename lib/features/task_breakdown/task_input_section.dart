import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class TaskInputSection extends StatefulWidget {
  final TextEditingController taskController;

  TaskInputSection({required this.taskController});

  @override
  _TaskInputSectionState createState() => _TaskInputSectionState();
}

class _TaskInputSectionState extends State<TaskInputSection> {
  DateTime? selectedDueDate;

  // Method to show date picker
  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != selectedDueDate) {
      setState(() {
        selectedDueDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: widget.taskController,
            decoration: InputDecoration(
              labelText: "Enter Task",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                selectedDueDate == null
                    ? "Select Due Date"
                    : "Due Date: ${selectedDueDate!.toLocal().toString().split(' ')[0]}",
                style: TextStyle(fontSize: 16),
              ),
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () => _selectDueDate(context),
              ),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.taskController.text.isNotEmpty && selectedDueDate != null) {
                Provider.of<AppState>(context, listen: false)
                    .addTask(widget.taskController.text, selectedDueDate!);
                widget.taskController.clear();
                setState(() {
                  selectedDueDate = null;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Please enter a task and select a due date"),
                ));
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
