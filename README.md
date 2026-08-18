# FocusFlow

FocusFlow is a Flutter productivity app for ADHD-friendly task planning, focus timing, and mood check-ins. The current build is mobile-first and local-first: tasks, subtasks, reminders, settings, moods, and timer sessions are persisted on the device with SQLite.

The product direction is intentionally calm. The Home screen should help the user choose one useful next action without turning into a dashboard full of pressure.

## Current App Shape

Primary navigation:

- **Home** - the daily command center with the current task, capacity setting, next-task preview, gentle waiting-task nudges, daily review prompts, mood summary, and timer summary.
- **Tasks** - task capture, due dates, Now/Next/Later/Done grouping, subtasks, time estimates, support metadata, reminders, and linked focus controls.
- **Timer** - Focus, Short Break, and Long Break modes with task/subtask context, active-session controls, completion prompts, presets, notifications, and timer history.
- **Mood** - mood check-in and mood history.

## Implemented Features

### Task and Step Planning

- Add, edit, delete, restore, and complete tasks.
- Add subtasks with optional minute estimates.
- Organize work into Now, Next, Later, and Done.
- Track task support context such as friction, energy, time estimate, and anxiety level.
- Generate or reuse a tiny next step when the user feels stuck.

### Task-Linked Timer

- Start a 2-minute or 5-minute focus session from the Home screen.
- Start a timer directly from a task or subtask.
- Show clear active focus state on Home, Tasks, and Timer.
- End a focus session early and still record elapsed time.
- Ask whether the linked task or step is complete when a focus session ends.
- Continue focus, leave work open, mark complete, or move into break-ready state.

### Quiet Progress Memory

- Timer history stores the task or subtask title snapshot, target type, elapsed seconds, and completion outcome.
- Expanded task cards show focused minutes, estimates, and whether work was under, close to, or over the estimate.
- Subtasks show their own focused minutes without adding clutter to collapsed task rows.
- Home can suggest resuming a task or step that was previously left open, inside the collapsible Next section.

### Dashboard and Daily Support

- Current task card adapts copy to mood and capacity.
- Daily plan scoring recommends a calm Now task and up to two Next tasks from due dates, capacity, task size, progress memory, and left-open timer sessions.
- Plan reasons such as `Due today`, `Small enough`, `Shrink first`, and `Left open` explain recommendations without exposing scores.
- Daily stats show focus minutes, sessions, completed tasks, and completed steps.
- Capacity selector supports low, medium, and high energy days.
- Waiting-task card offers shrink, move later, start tiny focus, and reminder actions.
- Daily review helps capture what counted and choose a tomorrow starter.

### Mood, Settings, and Notifications

- Mood check-ins include accessible selection state and history.
- Light and dark themes are supported.
- Timer and task reminder notifications can be enabled from settings.
- Default timer durations, default due date behavior, reminder style, and theme are persisted.

## Storage Model

FocusFlow currently uses local SQLite storage through repository interfaces:

- `tasks` and `subtasks`
- `moods`
- `settings`
- `task_reminders`
- `timer_sessions`

This is the right fit for the current mobile app because it works offline, keeps the implementation simple, and avoids account/cloud complexity. A future web app or multi-device app would need a hosted database and authentication layer.

## Tech Stack

- Flutter and Dart
- Provider for state management
- sqflite for local SQLite persistence
- flutter_local_notifications and timezone for local reminders
- intl for date formatting
- flutter_test, fake_async, and sqflite_common_ffi for tests

## Project Structure

```text
lib/
  database/       SQLite database implementations and migrations
  features/
    dashboard/    Home dashboard
    home/         Bottom navigation shell
    mood_tracker/ Mood check-in and history
    settings/     App settings
    task_breakdown/
                  Task list, subtasks, estimates, reminders, support flow
    timer/        Timer, presets, linked completion, history
    tracker/      Legacy progress tracker screen
    hyperfocus/   Legacy/parked hyperfocus screen
  models/         Task, subtask, mood, reminder, and timer session models
  providers/      App state and business logic
  repositories/   Storage interfaces
  services/       Notification service interfaces and local implementations
  theme/          Light/dark theme and semantic colors
  widgets/        Shared UI such as support sheets and timer completion prompt
test/             Unit, widget, smoke, database, and design-system tests
```

## Getting Started

1. Install Flutter.
2. Get packages:

   ```bash
   flutter pub get
   ```

3. Run the app:

   ```bash
   flutter run
   ```

4. Run tests:

   ```bash
   flutter test
   ```

5. Run static analysis:

   ```bash
   flutter analyze
   ```

## Current Verification

As of the Phase 7 implementation:

- `flutter test` passes with 127 tests.
- `flutter analyze` completes with the existing info-only deprecation baseline.

## Phase Status

- **Phase 1** - Task/timer direction and initial linked-flow foundation.
- **Phase 2** - Task estimates and subtask timer controls.
- **Phase 3** - Timer completion prompt and task/subtask outcome recording.
- **Phase 4** - Active focus visibility and early end controls.
- **Phase 5** - High-UX active state polish across Home, Tasks, Timer, and dark mode.
- **Phase 6** - Quiet progress memory, history labels, estimate feedback, and resume suggestion.
- **Phase 7** - Deterministic daily plan scoring, explainable plan reasons, capacity-aware task recommendations, and quiet recommendation badges.

## Next Planning Questions

Before starting the next phase, decide whether the app should prioritize:

- Better planning intelligence: smarter daily plan, recurring tasks, or templates.
- Better review/history: richer insights from completed sessions and mood/task patterns.
- App readiness: desktop build polish, backups/export, onboarding, or settings cleanup.
- Sync/web direction: authentication, cloud database, and cross-device data model.
