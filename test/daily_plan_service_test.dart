import 'package:adhd_list/models/daily_plan.dart';
import 'package:adhd_list/models/subtask.dart';
import 'package:adhd_list/models/task.dart';
import 'package:adhd_list/providers/timer_state.dart';
import 'package:adhd_list/services/daily_plan_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('DailyPlanService', () {
    final today = DateTime(2026, 8, 3);

    test('prioritizes due today tasks at medium capacity', () {
      final timerState = TimerState(
        sessionRepository: FakeTimerSessionRepository(),
      );
      addTearDown(timerState.dispose);
      final service = DailyPlanService(now: () => today);

      final plan = service.build(
        tasks: [
          _task(
            id: 1,
            title: 'Tomorrow task',
            dueDate: today.add(const Duration(days: 1)),
            estimatedMinutes: 5,
          ),
          _task(
            id: 2,
            title: 'Today task',
            dueDate: today,
            estimatedMinutes: 25,
          ),
        ],
        timerState: timerState,
        capacity: DailyCapacity.medium,
        mood: '',
      );

      expect(plan.nowTask?.title, 'Today task');
      expect(plan.insightFor(2)?.reason, 'Due today');
      expect(plan.nextTasks.single.title, 'Tomorrow task');
    });

    test('low capacity prefers a small task over a large overdue task', () {
      final timerState = TimerState(
        sessionRepository: FakeTimerSessionRepository(),
      );
      addTearDown(timerState.dispose);
      final service = DailyPlanService(now: () => today);

      final plan = service.build(
        tasks: [
          _task(
            id: 1,
            title: 'Large overdue task',
            dueDate: today.subtract(const Duration(days: 1)),
            estimatedMinutes: 60,
          ),
          _task(
            id: 2,
            title: 'Tiny admin task',
            dueDate: today.add(const Duration(days: 1)),
            estimatedMinutes: 5,
          ),
        ],
        timerState: timerState,
        capacity: DailyCapacity.low,
        mood: '',
      );

      expect(plan.nowTask?.title, 'Tiny admin task');
      expect(plan.insightFor(2)?.badgeLabel, 'Good low-capacity task');
      expect(plan.insightFor(1)?.badgeLabel, 'Needs smaller step');
    });

    test('left-open focus can become the recommended task', () async {
      final timerState = TimerState(
        sessionRepository: FakeTimerSessionRepository(
          sessions: [
            {
              'id': 1,
              'mode': 'Focus',
              'started_at': DateTime(2026, 8, 3, 8).toIso8601String(),
              'ended_at': DateTime(2026, 8, 3, 8, 5).toIso8601String(),
              'duration_seconds': 300,
              'completed': 1,
              'task_id': 2,
              'subtask_id': 20,
              'target_type': TimerState.targetTypeSubtask,
              'target_title_snapshot': 'Draft outline',
              'outcome': TimerState.outcomeLeftOpen,
            },
          ],
        ),
      );
      addTearDown(timerState.dispose);
      await timerState.loadSessionHistory();
      final service = DailyPlanService(now: () => today);

      final plan = service.build(
        tasks: [
          _task(
            id: 1,
            title: 'Normal task',
            dueDate: today.add(const Duration(days: 1)),
          ),
          _task(
            id: 2,
            title: 'Essay',
            dueDate: today.add(const Duration(days: 2)),
            subtasks: [
              Subtask(id: 20, title: 'Draft outline', estimatedMinutes: 5),
            ],
          ),
        ],
        timerState: timerState,
        capacity: DailyCapacity.medium,
        mood: '',
      );

      expect(plan.nowTask?.title, 'Essay');
      expect(plan.insightFor(2)?.reason, 'Left open');
      expect(plan.insightFor(2)?.targetTitle, 'Draft outline');
    });

    test('ignores left-open sessions for completed subtasks', () async {
      final timerState = TimerState(
        sessionRepository: FakeTimerSessionRepository(
          sessions: [
            {
              'id': 1,
              'mode': 'Focus',
              'started_at': DateTime(2026, 8, 3, 8).toIso8601String(),
              'ended_at': DateTime(2026, 8, 3, 8, 5).toIso8601String(),
              'duration_seconds': 300,
              'completed': 1,
              'task_id': 2,
              'subtask_id': 20,
              'target_type': TimerState.targetTypeSubtask,
              'target_title_snapshot': 'Draft outline',
              'outcome': TimerState.outcomeLeftOpen,
            },
          ],
        ),
      );
      addTearDown(timerState.dispose);
      await timerState.loadSessionHistory();
      final service = DailyPlanService(now: () => today);

      final plan = service.build(
        tasks: [
          _task(
            id: 1,
            title: 'Normal task',
            dueDate: today,
          ),
          _task(
            id: 2,
            title: 'Essay',
            dueDate: today.add(const Duration(days: 2)),
            subtasks: [
              Subtask(
                id: 20,
                title: 'Draft outline',
                isCompleted: true,
                estimatedMinutes: 5,
              ),
            ],
          ),
        ],
        timerState: timerState,
        capacity: DailyCapacity.medium,
        mood: '',
      );

      expect(plan.nowTask?.title, 'Normal task');
      expect(plan.insightFor(2)?.reason, isNot('Left open'));
    });
  });
}

Task _task({
  required int id,
  required String title,
  required DateTime dueDate,
  int? estimatedMinutes,
  List<Subtask>? subtasks,
}) {
  return Task(
    id: id,
    title: title,
    dueDate: dueDate,
    estimatedMinutes: estimatedMinutes,
    subtasks: subtasks,
  );
}
