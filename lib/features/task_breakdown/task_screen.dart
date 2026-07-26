import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_state.dart';
import '../../theme/app_theme.dart';
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
                if (taskState.loadError != null && taskState.tasks.isEmpty) {
                  return _TaskLoadError(
                    message: taskState.loadError!,
                    onRetry: taskState.loadTasks,
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

class _TaskLoadError extends StatelessWidget {
  const _TaskLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: cs.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tasks could not load',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: const Key('retry-load-tasks'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
