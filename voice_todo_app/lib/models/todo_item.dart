import 'dart:convert';

enum Priority { low, medium, high }

// reminder_frequency values: 'none' | 'once' | 'daily' | 'weekly'
class TodoItem {
  final String id;
  String title;
  String? description;
  bool isCompleted;
  Priority priority;
  DateTime createdAt;
  DateTime? completedAt;
  String? detectedLanguage;
  DateTime? reminderAt;
  String reminderFrequency;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = Priority.medium,
    required this.createdAt,
    this.completedAt,
    this.detectedLanguage,
    this.reminderAt,
    this.reminderFrequency = 'none',
  });

  TodoItem copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    Priority? priority,
    DateTime? completedAt,
    DateTime? reminderAt,
    String? reminderFrequency,
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
      reminderAt: reminderAt ?? this.reminderAt,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
    );
  }

  // Supabase row → TodoItem (snake_case columns)
  factory TodoItem.fromSupabase(Map<String, dynamic> row) => TodoItem(
        id: row['id'] as String,
        title: row['title'] as String,
        description: row['description'] as String?,
        isCompleted: row['is_completed'] as bool? ?? false,
        priority: Priority.values.firstWhere(
          (p) => p.name == row['priority'],
          orElse: () => Priority.medium,
        ),
        createdAt: DateTime.parse(row['created_at'] as String),
        completedAt: row['completed_at'] != null
            ? DateTime.parse(row['completed_at'] as String)
            : null,
        detectedLanguage: row['detected_language'] as String?,
        reminderAt: row['reminder_at'] != null
            ? DateTime.parse(row['reminder_at'] as String)
            : null,
        reminderFrequency: row['reminder_frequency'] as String? ?? 'none',
      );

  // TodoItem → Supabase INSERT payload
  Map<String, dynamic> toSupabaseInsert() => {
        'title': title,
        'description': description,
        'is_completed': isCompleted,
        'priority': priority.name,
        'created_at': createdAt.toUtc().toIso8601String(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'detected_language': detectedLanguage,
        if (reminderAt != null)
          'reminder_at': reminderAt!.toUtc().toIso8601String(),
        'reminder_frequency': reminderFrequency,
      };

  // Legacy local JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'priority': priority.index,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'detectedLanguage': detectedLanguage,
        'reminderAt': reminderAt?.toIso8601String(),
        'reminderFrequency': reminderFrequency,
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        priority: Priority.values[json['priority'] as int? ?? 1],
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        detectedLanguage: json['detectedLanguage'] as String?,
        reminderAt: json['reminderAt'] != null
            ? DateTime.parse(json['reminderAt'] as String)
            : null,
        reminderFrequency: json['reminderFrequency'] as String? ?? 'none',
      );

  String toJsonString() => jsonEncode(toJson());
  factory TodoItem.fromJsonString(String s) => TodoItem.fromJson(jsonDecode(s));
}
