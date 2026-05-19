import 'todo_item.dart';

class PendingAdd {
  final String title;
  final Priority priority;
  String reminderFrequency;
  DateTime? reminderAt;

  PendingAdd({
    required this.title,
    required this.priority,
    this.reminderFrequency = 'none',
    this.reminderAt,
  });
}
