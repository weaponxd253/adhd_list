import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/mood_state.dart';
import '../../providers/settings_state.dart';
import '../../providers/task_state.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: AppInsets.screenScrollPadding(context),
        children: [
          _SettingsSection(
            title: 'Appearance',
            children: [
              _ThemeModeControl(settings: settings),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            title: 'Timer',
            children: [
              _DurationRow(
                label: 'Focus',
                value: settings.focusDuration,
                onChanged: (value) => _updateDurations(
                  context,
                  focus: value,
                  shortBreak: settings.shortBreakDuration,
                  longBreak: settings.longBreakDuration,
                ),
              ),
              _SettingsDivider(),
              _DurationRow(
                label: 'Short break',
                value: settings.shortBreakDuration,
                onChanged: (value) => _updateDurations(
                  context,
                  focus: settings.focusDuration,
                  shortBreak: value,
                  longBreak: settings.longBreakDuration,
                ),
              ),
              _SettingsDivider(),
              _DurationRow(
                label: 'Long break',
                value: settings.longBreakDuration,
                onChanged: (value) => _updateDurations(
                  context,
                  focus: settings.focusDuration,
                  shortBreak: settings.shortBreakDuration,
                  longBreak: value,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            title: 'Tasks',
            children: [
              _DueDateDefaultControl(settings: settings),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            title: 'Data',
            children: [
              _DangerActionRow(
                icon: Icons.delete_sweep_outlined,
                label: 'Clear task history',
                onPressed: () => _confirmClearTasks(context),
              ),
              _SettingsDivider(),
              _DangerActionRow(
                icon: Icons.mood_bad_outlined,
                label: 'Clear mood history',
                onPressed: () => _confirmClearMoods(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SettingsSection(
            title: 'About',
            children: [
              _AboutRow(),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateDurations(
    BuildContext context, {
    required int focus,
    required int shortBreak,
    required int longBreak,
  }) async {
    try {
      await context.read<SettingsState>().setTimerDurations(
            focus: focus,
            shortBreak: shortBreak,
            longBreak: longBreak,
          );
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not save timer settings.');
    }
  }

  Future<void> _confirmClearTasks(BuildContext context) async {
    final confirmed = await _confirmDestructiveAction(
      context,
      title: 'Clear task history?',
      message: 'This permanently deletes all tasks and steps.',
      confirmLabel: 'Clear tasks',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await context.read<TaskState>().clearTaskHistory();
      if (context.mounted) _showMessage(context, 'Task history cleared');
    } catch (_) {
      if (context.mounted) _showMessage(context, 'Could not clear tasks.');
    }
  }

  Future<void> _confirmClearMoods(BuildContext context) async {
    final confirmed = await _confirmDestructiveAction(
      context,
      title: 'Clear mood history?',
      message: 'This permanently deletes all saved mood entries.',
      confirmLabel: 'Clear moods',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await context.read<MoodState>().clearMoodHistory();
      if (context.mounted) _showMessage(context, 'Mood history cleared');
    } catch (_) {
      if (context.mounted) _showMessage(context, 'Could not clear moods.');
    }
  }

  Future<bool> _confirmDestructiveAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final danger =
            Theme.of(dialogContext).extension<AppSemanticColors>()!.danger;

        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: danger),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ThemeModeControl extends StatelessWidget {
  const _ThemeModeControl({required this.settings});

  final SettingsState settings;

  @override
  Widget build(BuildContext context) {
    return _SettingsControlBlock(
      icon: Icons.contrast_rounded,
      label: 'Theme',
      control: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_outlined),
            label: Text('Light'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_outlined),
            label: Text('Dark'),
          ),
        ],
        selected: {settings.themeMode},
        showSelectedIcon: false,
        onSelectionChanged: (selection) async {
          try {
            await context.read<SettingsState>().setThemeMode(selection.first);
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not save theme setting.')),
            );
          }
        },
      ),
    );
  }
}

class _DueDateDefaultControl extends StatelessWidget {
  const _DueDateDefaultControl({required this.settings});

  final SettingsState settings;

  @override
  Widget build(BuildContext context) {
    return _SettingsControlBlock(
      icon: Icons.event_available_outlined,
      label: 'Default due date',
      control: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 1, label: Text('Tomorrow')),
          ButtonSegment(value: 7, label: Text('7 days')),
          ButtonSegment(value: 30, label: Text('30 days')),
        ],
        selected: {settings.defaultDueDateOffsetDays},
        showSelectedIcon: false,
        onSelectionChanged: (selection) async {
          try {
            await context
                .read<SettingsState>()
                .setDefaultDueDateOffsetDays(selection.first);
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not save task setting.')),
            );
          }
        },
      ),
    );
  }
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Icons.timer_outlined,
      label: label,
      trailing: _StepperControl(
        id: label.toLowerCase().replaceAll(' ', '-'),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _StepperControl extends StatelessWidget {
  const _StepperControl({
    required this.id,
    required this.value,
    required this.onChanged,
  });

  final String id;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canDecrease = value > SettingsState.minTimerMinutes;
    final canIncrease = value < SettingsState.maxTimerMinutes;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          key: Key('decrease-$id-duration'),
          tooltip: 'Decrease',
          onPressed: canDecrease ? () => onChanged(value - 1) : null,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            fixedSize: const Size(40, 40),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${value}m',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        IconButton.filledTonal(
          key: Key('increase-$id-duration'),
          tooltip: 'Increase',
          onPressed: canIncrease ? () => onChanged(value + 1) : null,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            fixedSize: const Size(40, 40),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _DangerActionRow extends StatelessWidget {
  const _DangerActionRow({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final danger = Theme.of(context).extension<AppSemanticColors>()!.danger;

    return _SettingsRow(
      icon: icon,
      iconColor: danger,
      label: label,
      labelColor: danger,
      trailing: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: const Icon(Icons.chevron_right_rounded),
        color: danger,
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow();

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Icons.info_outline_rounded,
      label: 'FocusFlow',
      trailing: Text(
        'Version 1.0.0',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _SettingsControlBlock extends StatelessWidget {
  const _SettingsControlBlock({
    required this.icon,
    required this.label,
    required this.control,
  });

  final IconData icon;
  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: control,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: labelColor,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
              child: Align(alignment: Alignment.centerRight, child: trailing)),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
