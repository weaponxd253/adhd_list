enum TaskFriction {
  tooBig,
  unclear,
  boring,
  anxious,
  lowEnergy,
  tooManySteps,
  avoiding,
  distracted,
}

enum TaskEnergyLevel { low, medium, high }

enum TaskTimeEstimate { twoMinutes, fiveMinutes, tenMinutes, twentyFivePlus }

enum TaskAnxietyLevel { calm, tense, high }

const taskRescueFrictionOptions = <TaskFriction>[
  TaskFriction.tooBig,
  TaskFriction.unclear,
  TaskFriction.anxious,
  TaskFriction.lowEnergy,
  TaskFriction.distracted,
];

extension TaskFrictionDetails on TaskFriction {
  String get id => name;

  String get label {
    switch (this) {
      case TaskFriction.tooBig:
        return 'Too big';
      case TaskFriction.unclear:
        return 'Not sure where to start';
      case TaskFriction.boring:
        return 'Boring';
      case TaskFriction.anxious:
        return 'Anxious about it';
      case TaskFriction.lowEnergy:
        return 'No energy';
      case TaskFriction.tooManySteps:
        return 'Too many steps';
      case TaskFriction.avoiding:
        return "I'm avoiding it";
      case TaskFriction.distracted:
        return 'Distracted';
    }
  }

  String tinyStepFor(String taskTitle) {
    switch (this) {
      case TaskFriction.tooBig:
        return 'Write the smallest visible part of "$taskTitle".';
      case TaskFriction.unclear:
        return 'Open the task and decide what "done enough" means.';
      case TaskFriction.boring:
        return 'Do the first two minutes while making it mildly pleasant.';
      case TaskFriction.anxious:
        return 'Open "$taskTitle" and do the lowest-risk version that counts.';
      case TaskFriction.lowEnergy:
        return 'Set up only the next object, tab, or place you need.';
      case TaskFriction.tooManySteps:
        return 'Pick one step and ignore the rest for five minutes.';
      case TaskFriction.avoiding:
        return 'Touch the task once: open it, move it, or name the blocker.';
      case TaskFriction.distracted:
        return 'Put away one distraction, then work on "$taskTitle" for two minutes.';
    }
  }

  String get supportPrompt {
    switch (this) {
      case TaskFriction.tooBig:
        return 'Shrink the task until it feels almost silly.';
      case TaskFriction.unclear:
        return 'Clarity first. Action second.';
      case TaskFriction.boring:
        return 'Lower the demand and add a little novelty.';
      case TaskFriction.anxious:
        return 'What would make this 10% easier?';
      case TaskFriction.lowEnergy:
        return 'Use setup as progress.';
      case TaskFriction.tooManySteps:
        return 'One lane. One step.';
      case TaskFriction.avoiding:
        return 'No shame. Just a tiny re-entry.';
      case TaskFriction.distracted:
        return 'One tab, one place, one next action.';
    }
  }

  List<String> get reframes {
    switch (this) {
      case TaskFriction.anxious:
        return const [
          'Do the version that counts, not the perfect version.',
          'For two minutes, only open the task.',
        ];
      case TaskFriction.tooBig:
        return const ['Make it smaller than feels necessary.'];
      case TaskFriction.unclear:
        return const ['Define done enough before doing more.'];
      case TaskFriction.lowEnergy:
        return const ['Setup counts when energy is low.'];
      case TaskFriction.distracted:
        return const ['Move one distraction out of reach first.'];
      case TaskFriction.boring:
        return const ['Add novelty, sound, or a tiny race.'];
      case TaskFriction.tooManySteps:
        return const ['Hide the list after choosing one lane.'];
      case TaskFriction.avoiding:
        return const ['Re-entry is progress.'];
    }
  }

  int get suggestedMinutes {
    switch (this) {
      case TaskFriction.lowEnergy:
      case TaskFriction.anxious:
      case TaskFriction.distracted:
        return 2;
      case TaskFriction.tooBig:
      case TaskFriction.unclear:
      case TaskFriction.avoiding:
        return 5;
      case TaskFriction.boring:
      case TaskFriction.tooManySteps:
        return 10;
    }
  }
}

extension TaskEnergyDetails on TaskEnergyLevel {
  String get id => name;

  String get label {
    switch (this) {
      case TaskEnergyLevel.low:
        return 'Low';
      case TaskEnergyLevel.medium:
        return 'Medium';
      case TaskEnergyLevel.high:
        return 'High';
    }
  }
}

extension TaskTimeEstimateDetails on TaskTimeEstimate {
  String get id => name;

  String get label {
    switch (this) {
      case TaskTimeEstimate.twoMinutes:
        return '2 min';
      case TaskTimeEstimate.fiveMinutes:
        return '5 min';
      case TaskTimeEstimate.tenMinutes:
        return '10 min';
      case TaskTimeEstimate.twentyFivePlus:
        return '25+ min';
    }
  }
}

extension TaskAnxietyDetails on TaskAnxietyLevel {
  String get id => name;

  String get label {
    switch (this) {
      case TaskAnxietyLevel.calm:
        return 'Calm';
      case TaskAnxietyLevel.tense:
        return 'Tense';
      case TaskAnxietyLevel.high:
        return 'High';
    }
  }
}

TaskFriction? taskFrictionFromId(String? value) {
  for (final friction in TaskFriction.values) {
    if (friction.id == value) return friction;
  }
  return null;
}

TaskEnergyLevel? taskEnergyLevelFromId(String? value) {
  for (final level in TaskEnergyLevel.values) {
    if (level.id == value) return level;
  }
  return null;
}

TaskTimeEstimate? taskTimeEstimateFromId(String? value) {
  for (final estimate in TaskTimeEstimate.values) {
    if (estimate.id == value) return estimate;
  }
  return null;
}

TaskAnxietyLevel? taskAnxietyLevelFromId(String? value) {
  for (final level in TaskAnxietyLevel.values) {
    if (level.id == value) return level;
  }
  return null;
}
