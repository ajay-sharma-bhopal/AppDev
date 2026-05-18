import 'dart:convert';

enum Priority { low, medium, high }

class TodoItem {
  final String id;
  String title;
  String? description;
  bool isCompleted;
  Priority priority;
  DateTime createdAt;
  DateTime? completedAt;
  String? detectedLanguage;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = Priority.medium,
    required this.createdAt,
    this.completedAt,
    this.detectedLanguage,
  });

  TodoItem copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    Priority? priority,
    DateTime? completedAt,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      detectedLanguage: detectedLanguage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'priority': priority.index,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'detectedLanguage': detectedLanguage,
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        isCompleted: json['isCompleted'] ?? false,
        priority: Priority.values[json['priority'] ?? 1],
        createdAt: DateTime.parse(json['createdAt']),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        detectedLanguage: json['detectedLanguage'],
      );

  String toJsonString() => jsonEncode(toJson());

  factory TodoItem.fromJsonString(String jsonString) =>
      TodoItem.fromJson(jsonDecode(jsonString));
}
