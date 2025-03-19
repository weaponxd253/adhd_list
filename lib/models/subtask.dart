class Subtask {
  int id;  // 
  String title;
  bool isCompleted;

  Subtask({
    required this.id,  // 
    required this.title,
    this.isCompleted = false,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  // Create Subtask from a Map (used when fetching from DB)
  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'],  // ✅ Load ID from DB
      title: map['title'],
      isCompleted: map['is_completed'] == 1,
    );
  }
}
