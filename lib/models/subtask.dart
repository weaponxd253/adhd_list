class Subtask {
  int id;
  String title;
  bool isCompleted;
  int? estimatedMinutes;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.estimatedMinutes,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'estimated_minutes': estimatedMinutes,
    };
  }

  // Create Subtask from a Map (used when fetching from DB)
  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'],
      title: map['title'],
      isCompleted: map['is_completed'] == 1,
      estimatedMinutes: map['estimated_minutes'] as int?,
    );
  }
}
