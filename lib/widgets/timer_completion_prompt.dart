import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_state.dart';
import '../providers/timer_state.dart';
import '../theme/app_theme.dart';

void showPendingTimerCompletionPrompt(BuildContext context) {
  final timerState = context.read<TimerState>();
  final message = timerState.completionMessage;
  if (message == null) return;

  final linkedTarget = timerState.pendingCompletionTarget;
  timerState.clearCompletionMessage();
  showTimerCompletionPrompt(
    context: context,
    detail: message,
    linkedTarget: linkedTarget,
  );
}

void showTimerCompletionPrompt({
  required BuildContext context,
  required String detail,
  required TimerCompletionTarget? linkedTarget,
}) {
  if (linkedTarget == null) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _CompletionPromptSheet(
        detail: detail,
        onKeepGoing: () {
          Navigator.pop(sheetContext);
          if (!context.mounted) return;
          context.read<TimerState>().startQuickFocus(5);
        },
        onDone: () => Navigator.pop(sheetContext),
      ),
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => _LinkedCompletionPromptSheet(
      target: linkedTarget,
      onMarkComplete: () {
        Navigator.pop(sheetContext);
        unawaited(_markLinkedComplete(context, linkedTarget));
      },
      onAddFive: () {
        Navigator.pop(sheetContext);
        unawaited(_continueLinkedFocus(context));
      },
      onLeaveOpen: () {
        Navigator.pop(sheetContext);
        unawaited(
          context
              .read<TimerState>()
              .resolveLinkedCompletion(TimerState.outcomeLeftOpen),
        );
      },
      onTakeBreak: () {
        Navigator.pop(sheetContext);
        unawaited(
          context
              .read<TimerState>()
              .resolveLinkedCompletion(TimerState.outcomeBreakReady),
        );
      },
    ),
  );
}

Future<void> _markLinkedComplete(
  BuildContext context,
  TimerCompletionTarget target,
) async {
  try {
    final taskState = context.read<TaskState>();
    final timerState = context.read<TimerState>();
    if (target.isSubtask) {
      await taskState.completeSubtask(target.taskId, target.subtaskId!);
      await timerState.resolveLinkedCompletion(
        TimerState.outcomeSubtaskCompleted,
      );
    } else {
      await taskState.completeTask(target.taskId);
      await timerState.resolveLinkedCompletion(TimerState.outcomeTaskCompleted);
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not mark that complete.')),
    );
  }
}

Future<void> _continueLinkedFocus(BuildContext context) async {
  final started = await context.read<TimerState>().continueLinkedFocus();
  if (started || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Could not add more time.')),
  );
}

class _CompletionPromptSheet extends StatelessWidget {
  const _CompletionPromptSheet({
    required this.detail,
    required this.onKeepGoing,
    required this.onDone,
  });

  final String detail;
  final VoidCallback onKeepGoing;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: cs.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'That counted.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Want to keep going or stop here?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const Key('completion-keep-going'),
              onPressed: onKeepGoing,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Keep going'),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton(
              key: const Key('completion-done-for-now'),
              onPressed: onDone,
              child: const Text('Done for now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedCompletionPromptSheet extends StatelessWidget {
  const _LinkedCompletionPromptSheet({
    required this.target,
    required this.onMarkComplete,
    required this.onAddFive,
    required this.onLeaveOpen,
    required this.onTakeBreak,
  });

  final TimerCompletionTarget target;
  final VoidCallback onMarkComplete;
  final VoidCallback onAddFive;
  final VoidCallback onLeaveOpen;
  final VoidCallback onTakeBreak;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final markLabel =
        target.isSubtask ? 'Mark step complete' : 'Mark task complete';

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, color: cs.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Did that get finished?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                target.title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                key: const Key('linked-completion-mark-complete'),
                onPressed: onMarkComplete,
                icon: const Icon(Icons.check_rounded),
                label: Text(markLabel),
              ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                key: const Key('linked-completion-add-five'),
                onPressed: onAddFive,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Add 5 min'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      key: const Key('linked-completion-leave-open'),
                      onPressed: onLeaveOpen,
                      child: const Text('Leave open'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: TextButton(
                      key: const Key('linked-completion-take-break'),
                      onPressed: onTakeBreak,
                      child: const Text('Take break'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
