import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_item.dart';
import '../services/command_parser.dart';
import '../services/voice_service.dart';

class TodoProvider extends ChangeNotifier {
  final List<TodoItem> _todos = [];
  final CommandParser _parser = CommandParser();
  final VoiceService voiceService = VoiceService();
  final _uuid = const Uuid();

  String _lastCommandFeedback = '';
  bool _isInitialized = false;
  String _filterMode = 'all'; // all, active, completed

  List<TodoItem> get todos {
    switch (_filterMode) {
      case 'active':
        return _todos.where((t) => !t.isCompleted).toList();
      case 'completed':
        return _todos.where((t) => t.isCompleted).toList();
      default:
        return List.unmodifiable(_todos);
    }
  }

  List<TodoItem> get allTodos => List.unmodifiable(_todos);
  int get activeCount => _todos.where((t) => !t.isCompleted).length;
  int get completedCount => _todos.where((t) => t.isCompleted).length;
  String get lastCommandFeedback => _lastCommandFeedback;
  bool get isInitialized => _isInitialized;
  String get filterMode => _filterMode;

  Future<void> initialize() async {
    await _loadTodos();
    final available = await voiceService.initialize();
    if (available) {
      voiceService.onCommandReceived = processVoiceCommand;
    }
    _isInitialized = true;
    notifyListeners();
  }

  void setFilter(String mode) {
    _filterMode = mode;
    notifyListeners();
  }

  void processVoiceCommand(String text) {
    final command = _parser.parse(text);

    switch (command.type) {
      case CommandType.addTask:
        if (command.taskTitle != null && command.taskTitle!.isNotEmpty) {
          _addTask(command.taskTitle!, command.priority ?? Priority.medium);
          _lastCommandFeedback = 'Added: "${command.taskTitle}"';
          voiceService.speakTaskAdded(command.taskTitle!);
        }
        break;

      case CommandType.completeTask:
        final matched = _findTask(command.taskTitle);
        if (matched != null) {
          _completeTask(matched.id);
          _lastCommandFeedback = 'Completed: "${matched.title}"';
          voiceService.speakTaskCompleted(matched.title);
        } else {
          _lastCommandFeedback = 'No task found matching "${command.taskTitle}"';
          voiceService.speakNoTaskFound();
        }
        break;

      case CommandType.deleteTask:
        final matched = _findTask(command.taskTitle);
        if (matched != null) {
          _deleteTask(matched.id);
          _lastCommandFeedback = 'Deleted: "${matched.title}"';
          voiceService.speakTaskDeleted(matched.title);
        } else {
          _lastCommandFeedback = 'No task found matching "${command.taskTitle}"';
          voiceService.speakNoTaskFound();
        }
        break;

      case CommandType.listTasks:
        _lastCommandFeedback = 'You have ${activeCount} active task${activeCount != 1 ? 's' : ''}';
        voiceService.speak(_lastCommandFeedback);
        break;

      case CommandType.clearCompleted:
        final count = completedCount;
        _clearCompleted();
        _lastCommandFeedback = 'Cleared $count completed task${count != 1 ? 's' : ''}';
        voiceService.speak(_lastCommandFeedback);
        break;

      case CommandType.unknown:
        _lastCommandFeedback = 'Could not understand: "$text"';
        break;
    }

    notifyListeners();
  }

  // Manual CRUD methods
  void addTaskManually(String title, {Priority priority = Priority.medium}) {
    _addTask(title, priority);
    _lastCommandFeedback = 'Added: "$title"';
    notifyListeners();
  }

  void toggleTask(String id) {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final todo = _todos[idx];
    _todos[idx] = todo.copyWith(
      isCompleted: !todo.isCompleted,
      completedAt: !todo.isCompleted ? DateTime.now() : null,
    );
    _saveTodos();
    notifyListeners();
  }

  void deleteTask(String id) {
    _deleteTask(id);
    notifyListeners();
  }

  void updateTask(String id, String newTitle) {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _todos[idx] = _todos[idx].copyWith(title: newTitle);
    _saveTodos();
    notifyListeners();
  }

  void reorderTasks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _todos.removeAt(oldIndex);
    _todos.insert(newIndex, item);
    _saveTodos();
    notifyListeners();
  }

  // Private helpers
  void _addTask(String title, Priority priority) {
    _todos.insert(
      0,
      TodoItem(
        id: _uuid.v4(),
        title: title,
        priority: priority,
        createdAt: DateTime.now(),
      ),
    );
    _saveTodos();
  }

  void _completeTask(String id) {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _todos[idx] = _todos[idx].copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    _saveTodos();
  }

  void _deleteTask(String id) {
    _todos.removeWhere((t) => t.id == id);
    _saveTodos();
  }

  void _clearCompleted() {
    _todos.removeWhere((t) => t.isCompleted);
    _saveTodos();
  }

  TodoItem? _findTask(String? query) {
    if (query == null || query.isEmpty) return null;
    final lower = query.toLowerCase();
    // Exact match first
    try {
      return _todos.firstWhere((t) => t.title.toLowerCase() == lower);
    } catch (_) {}
    // Partial match
    try {
      return _todos.firstWhere(
        (t) => t.title.toLowerCase().contains(lower) || lower.contains(t.title.toLowerCase()),
      );
    } catch (_) {}
    return null;
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _todos.map((t) => t.toJsonString()).toList();
    await prefs.setStringList('todos', jsonList);
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('todos') ?? [];
    _todos.clear();
    for (final json in jsonList) {
      try {
        _todos.add(TodoItem.fromJsonString(json));
      } catch (_) {
        // Skip corrupt entries
      }
    }
  }

  @override
  void dispose() {
    voiceService.dispose();
    super.dispose();
  }
}
