import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/task_support.dart';
import '../providers/task_state.dart';
import '../providers/timer_state.dart';
import '../theme/app_theme.dart';

Future<void> showTaskSupportSheet({
  required BuildContext context,
  required Task task,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TaskSupportSheet(task: task),
  );
}

class _TaskSupportSheet extends StatefulWidget {
  const _TaskSupportSheet({required this.task});

  final Task task;

  @override
  State<_TaskSupportSheet> createState() => _TaskSupportSheetState();
}

class _TaskSupportSheetState extends State<_TaskSupportSheet> {
  late TaskFriction? _friction = widget.task.friction;
  late TaskEnergyLevel? _energyLevel = widget.task.energyLevel;
  late TaskTimeEstimate? _timeEstimate = widget.task.timeEstimate;
  late TaskAnxietyLevel? _anxietyLevel = widget.task.anxietyLevel;
  bool _saving = false;

  Task get _task => widget.task;

  Future<void> _save({
    TaskFriction? friction,
    TaskEnergyLevel? energyLevel,
    TaskTimeEstimate? timeEstimate,
    TaskAnxietyLevel? anxietyLevel,
  }) async {
    final nextFriction = friction ?? _friction;
    final nextEnergy = energyLevel ?? _energyLevel;
    final nextTime = timeEstimate ?? _timeEstimate;
    final nextAnxiety = anxietyLevel ?? _anxietyLevel;

    setState(() => _saving = true);
    try {
      await context.read<TaskState>().updateTaskSupport(
            _task.id,
            friction: nextFriction,
            energyLevel: nextEnergy,
            timeEstimate: nextTime,
            anxietyLevel: nextAnxiety,
          );
      if (!mounted) return;
      setState(() {
        _friction = nextFriction;
        _energyLevel = nextEnergy;
        _timeEstimate = nextTime;
        _anxietyLevel = nextAnxiety;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save support details.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectFriction(TaskFriction friction) {
    return _save(
      friction: friction,
      energyLevel: _energyLevel ?? _defaultEnergyFor(friction),
      timeEstimate:
          _timeEstimate ?? _timeFromMinutes(friction.suggestedMinutes),
      anxietyLevel: _anxietyLevel ?? _defaultAnxietyFor(friction),
    );
  }

  Future<void> _addTinyStep() async {
    setState(() => _saving = true);
    try {
      final added = await context.read<TaskState>().addTinyStep(_task.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added ? 'Tiny step added' : 'Tiny step is already there',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add the tiny step.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _startQuickFocus(int minutes) {
    final messenger = ScaffoldMessenger.of(context);
    context.read<TimerState>().startQuickFocus(minutes);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          minutes == 2
              ? '2 minute tiny focus started'
              : '$minutes minute focus started',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final taskState = context.watch<TaskState>();
    final selectedFriction = _friction;
    final suggestedMinutes = selectedFriction?.suggestedMinutes ?? 5;
    final tinyStep = taskState.tinyStepSuggestionFor(_task);
    final reframes = selectedFriction?.reframes ?? const <String>[];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('I am stuck', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _task.title,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "What's the blocker?",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final friction in taskRescueFrictionOptions)
                    ChoiceChip(
                      key: ValueKey('friction-${friction.id}'),
                      label: Text(friction.label),
                      selected: selectedFriction == friction,
                      onSelected:
                          _saving ? null : (_) => _selectFriction(friction),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.18),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedFriction?.supportPrompt ??
                            'Pick a blocker and I will make the next move smaller.',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      for (final reframe in reframes) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          reframe,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Next tiny step',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        tinyStep,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SupportChoiceGroup<TaskEnergyLevel>(
                label: 'Energy',
                values: TaskEnergyLevel.values,
                selected: _energyLevel,
                labelFor: (value) => value.label,
                idFor: (value) => 'energy-${value.id}',
                onSelected:
                    _saving ? null : (value) => _save(energyLevel: value),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SupportChoiceGroup<TaskTimeEstimate>(
                label: 'Time',
                values: TaskTimeEstimate.values,
                selected: _timeEstimate,
                labelFor: (value) => value.label,
                idFor: (value) => 'time-${value.id}',
                onSelected:
                    _saving ? null : (value) => _save(timeEstimate: value),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SupportChoiceGroup<TaskAnxietyLevel>(
                label: 'Anxiety',
                values: TaskAnxietyLevel.values,
                selected: _anxietyLevel,
                labelFor: (value) => value.label,
                idFor: (value) => 'anxiety-${value.id}',
                onSelected:
                    _saving ? null : (value) => _save(anxietyLevel: value),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  FilledButton.icon(
                    key: const Key('start-tiny-focus'),
                    onPressed: _saving ? null : () => _startQuickFocus(2),
                    icon: const Icon(Icons.bolt_rounded),
                    label: const Text('Start tiny'),
                  ),
                  if (suggestedMinutes != 2)
                    OutlinedButton.icon(
                      key: const Key('start-suggested-focus'),
                      onPressed: _saving
                          ? null
                          : () => _startQuickFocus(suggestedMinutes),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('Start ${suggestedMinutes}m'),
                    ),
                  OutlinedButton.icon(
                    key: const Key('add-tiny-step'),
                    onPressed: _saving ? null : _addTinyStep,
                    icon: const Icon(Icons.call_split_rounded),
                    label: const Text('Make smaller'),
                  ),
                  for (final minutes in const [5, 10])
                    OutlinedButton(
                      key: ValueKey('quick-focus-$minutes'),
                      onPressed:
                          _saving ? null : () => _startQuickFocus(minutes),
                      child: Text('${minutes}m'),
                    ),
                ],
              ),
              if (_saving) ...[
                const SizedBox(height: AppSpacing.sm),
                const LinearProgressIndicator(minHeight: 2),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TaskEnergyLevel _defaultEnergyFor(TaskFriction friction) {
    switch (friction) {
      case TaskFriction.lowEnergy:
      case TaskFriction.anxious:
      case TaskFriction.distracted:
        return TaskEnergyLevel.low;
      case TaskFriction.tooBig:
      case TaskFriction.tooManySteps:
        return TaskEnergyLevel.medium;
      case TaskFriction.unclear:
      case TaskFriction.boring:
      case TaskFriction.avoiding:
        return TaskEnergyLevel.medium;
    }
  }

  TaskTimeEstimate _timeFromMinutes(int minutes) {
    if (minutes <= 2) return TaskTimeEstimate.twoMinutes;
    if (minutes <= 5) return TaskTimeEstimate.fiveMinutes;
    if (minutes <= 10) return TaskTimeEstimate.tenMinutes;
    return TaskTimeEstimate.twentyFivePlus;
  }

  TaskAnxietyLevel _defaultAnxietyFor(TaskFriction friction) {
    switch (friction) {
      case TaskFriction.anxious:
      case TaskFriction.avoiding:
        return TaskAnxietyLevel.high;
      case TaskFriction.distracted:
      case TaskFriction.tooBig:
      case TaskFriction.unclear:
      case TaskFriction.tooManySteps:
        return TaskAnxietyLevel.tense;
      case TaskFriction.boring:
      case TaskFriction.lowEnergy:
        return TaskAnxietyLevel.calm;
    }
  }
}

class _SupportChoiceGroup<T> extends StatelessWidget {
  const _SupportChoiceGroup({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.idFor,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T? selected;
  final String Function(T value) labelFor;
  final String Function(T value) idFor;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final value in values)
              ChoiceChip(
                key: ValueKey(idFor(value)),
                label: Text(labelFor(value)),
                selected: selected == value,
                onSelected:
                    onSelected == null ? null : (_) => onSelected?.call(value),
              ),
          ],
        ),
      ],
    );
  }
}
