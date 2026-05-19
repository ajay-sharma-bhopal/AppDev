import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/todo_item.dart';
import '../services/command_parser.dart';
import '../services/voice_service.dart';

class TodoProvider extends ChangeNotifier {
  final List<TodoItem> _todos = [];
  final CommandParser _parser = CommandParser();
  final VoiceService voiceService = VoiceService();

  String _lastCommandFeedback = '';
  bool _isInitialized = false;
  String _filterMode = 'all';
  String? _currentUserId;
  RealtimeChannel? _realtimeChannel;

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
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || userId == _currentUserId) return;
    _currentUserId = userId;

    _isInitialized = false;
    _todos.clear();
    notifyListeners();

    await _loadTodos();
    _subscribeToRealtime();

    final available = await voiceService.initialize();
    if (available) voiceService.onCommandReceived = processVoiceCommand;

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _currentUserId = null;
    _isInitialized = false;
    _todos.clear();
    await supabase.auth.signOut();
    notifyListeners();
  }

  void reset() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _currentUserId = null;
    _isInitialized = false;
    _todos.clear();
    notifyListeners();
  }

  void setFilter(String mode) {
    _filterMode = mode;
    notifyListeners();
  }

  Future<void> processVoiceCommand(String text) async {
    final command = _parser.parse(text);

    switch (command.type) {
      case CommandType.addTask:
        if (command.taskTitle != null && command.taskTitle!.isNotEmpty) {
          await _addTask(command.taskTitle!, command.priority ?? Priority.medium);
          _lastCommandFeedback = 'Added: "${command.taskTitle}"';
          voiceService.speakTaskAdded(command.taskTitle!);
        }
        break;

      case CommandType.completeTask:
        final matched = _findTask(command.taskTitle);
        if (matched != null) {
          await _setCompleted(matched.id, true);
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
          final title = matched.title;
          await _deleteTask(matched.id);
          _lastCommandFeedback = 'Deleted: "$title"';
          voiceService.speakTaskDeleted(title);
        } else {
          _lastCommandFeedback = 'No task found matching "${command.taskTitle}"';
          voiceService.speakNoTaskFound();
        }
        break;

      case CommandType.listTasks:
        _lastCommandFeedback =
            'You have $activeCount active task${activeCount != 1 ? 's' : ''}';
        voiceService.speak(_lastCommandFeedback);
        break;

      case CommandType.clearCompleted:
        final count = completedCount;
        await _clearCompleted();
        _lastCommandFeedback =
            'Cleared $count completed task${count != 1 ? 's' : ''}';
        voiceService.speak(_lastCommandFeedback);
        break;

      case CommandType.unknown:
        _lastCommandFeedback = 'Could not understand: "$text"';
        break;
    }

    notifyListeners();
  }

  Future<void> addTaskManually(String title,
      {Priority priority = Priority.medium}) async {
    await _addTask(title, priority);
    _lastCommandFeedback = 'Added: "$title"';
    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final newCompleted = !_todos[idx].isCompleted;
    // Optimistic UI update
    _todos[idx] = _todos[idx].copyWith(
      isCompleted: newCompleted,
      completedAt: newCompleted ? DateTime.now() : null,
    );
    notifyListeners();
    await supabase.from('todos').update({
      'is_completed': newCompleted,
      'completed_at':
          newCompleted ? DateTime.now().toUtc().toIso8601String() : null,
    }).eq('id', id);
  }

  Future<void> deleteTask(String id) async {
    await _deleteTask(id);
    notifyListeners();
  }

  Future<void> updateTask(String id, String newTitle) async {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _todos[idx] = _todos[idx].copyWith(title: newTitle);
    notifyListeners();
    await supabase.from('todos').update({'title': newTitle}).eq('id', id);
  }

  // ── Private helpers ────────────────────────────────────────────────────

  Future<void> _addTask(String title, Priority priority) async {
    final row = await supabase
        .from('todos')
        .insert({
          'title': title,
          'priority': priority.name,
          'is_completed': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();
    _todos.insert(0, TodoItem.fromSupabase(row));
    notifyListeners();
  }

  Future<void> _setCompleted(String id, bool completed) async {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _todos[idx] = _todos[idx].copyWith(
      isCompleted: completed,
      completedAt: completed ? DateTime.now() : null,
    );
    await supabase.from('todos').update({
      'is_completed': completed,
      'completed_at':
          completed ? DateTime.now().toUtc().toIso8601String() : null,
    }).eq('id', id);
  }

  Future<void> _deleteTask(String id) async {
    _todos.removeWhere((t) => t.id == id);
    await supabase.from('todos').delete().eq('id', id);
  }

  Future<void> _clearCompleted() async {
    _todos.removeWhere((t) => t.isCompleted);
    await supabase
        .from('todos')
        .delete()
        .eq('is_completed', true);
  }

  Future<void> _loadTodos() async {
    try {
      final rows = await supabase
          .from('todos')
          .select()
          .order('created_at', ascending: false) as List;
      _todos
        ..clear()
        ..addAll(rows.map((r) => TodoItem.fromSupabase(r as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load todos: $e');
    }
  }

  void _subscribeToRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = supabase
        .channel('public:todos')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'todos',
          callback: (_) => _loadTodos(),
        )
        .subscribe();
  }

  TodoItem? _findTask(String? query) {
    if (query == null || query.isEmpty) return null;
    final lower = query.toLowerCase();
    try {
      return _todos.firstWhere((t) => t.title.toLowerCase() == lower);
    } catch (_) {}
    try {
      return _todos.firstWhere(
        (t) =>
            t.title.toLowerCase().contains(lower) ||
            lower.contains(t.title.toLowerCase()),
      );
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    voiceService.dispose();
    super.dispose();
  }
}
