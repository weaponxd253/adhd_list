# FocusFlow - Productivity & Mood Tracker App

## Overview
FocusFlow is a Flutter-based mobile application designed to help users with ADHD and anxiety enhance their productivity while tracking their mood. It integrates a task manager, Pomodoro timer, hyperfocus mode, and a mood tracker to provide a structured and supportive workflow.

## Features
### 1. **Dashboard**
   - Overview of tasks, progress, and upcoming tasks.
   - Displays Pomodoro timer status.
   - Quick access to the mood tracker.

### 2. **Task Management**
   - Create, edit, and manage tasks.
   - Set due dates and track completion progress.
   - Add subtasks for better task breakdown.

### 3. **Pomodoro Timer**
   - Timer with Focus, Short Break, and Long Break modes.
   - Start, pause, reset, and switch between modes.
   - Visual progress indicator.

### 4. **Hyperfocus Mode**
   - Customize background sounds (White Noise, Lo-fi Beats, Nature Sounds).
   - Adjustable focus session duration.
   - Start hyperfocus mode for deep work sessions.

### 5. **Mood Tracker**
   - Select moods with associated emojis.
   - View mood history over time.
   - Get suggestions based on selected moods.

### 6. **Habit & Progress Tracker**
   - Track streaks and earn points for completed tasks.
   - View recent accomplishments.

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/focusflow.git
   ```
2. Navigate to the project directory:
   ```bash
   cd focusflow
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Dependencies
- `flutter`
- `provider` (State management)
- `intl` (Date formatting)

## Folder Structure
```
lib/
 ├── features/
 │   ├── dashboard/ (Dashboard UI and logic)
 │   ├── mood_tracker/ (Mood tracking feature)
 │   ├── task_breakdown/ (Task management UI & logic)
 │   ├── timer/ (Pomodoro Timer UI & functionality)
 │   ├── hyperfocus/ (Hyperfocus mode UI)
 │   ├── tracker/ (Progress and streak tracking)
 │   └── home/ (Main navigation)
 ├── providers/ (State management using Provider)
 ├── widgets/ (Reusable UI components)
```

## Contribution
If you’d like to contribute:
1. Fork the repository.
2. Create a new branch:
   ```bash
   git checkout -b feature-name
   ```
3. Make changes and commit:
   ```bash
   git commit -m "Add new feature"
   ```
4. Push to the branch:
   ```bash
   git push origin feature-name
   ```
5. Open a Pull Request.

## License
This project is licensed under the MIT License.

