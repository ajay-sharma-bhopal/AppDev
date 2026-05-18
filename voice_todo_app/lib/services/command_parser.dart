import '../models/todo_item.dart';

enum CommandType {
  addTask,
  completeTask,
  deleteTask,
  listTasks,
  clearCompleted,
  unknown,
}

class ParsedCommand {
  final CommandType type;
  final String? taskTitle;
  final Priority? priority;
  final String rawText;

  ParsedCommand({
    required this.type,
    this.taskTitle,
    this.priority,
    required this.rawText,
  });
}

/// Parses voice commands in English and other languages.
/// Uses keyword matching with multilingual keyword sets.
class CommandParser {
  // Add task keywords across languages
  static const _addKeywords = [
    // English
    'add', 'create', 'new', 'remind me to', 'remember to', 'note',
    'task', 'todo', 'put', 'schedule', 'set',
    // Spanish
    'agregar', 'añadir', 'crear', 'nuevo', 'recordar', 'anotar',
    // French
    'ajouter', 'créer', 'nouveau', 'rappeler', 'noter',
    // German
    'hinzufügen', 'erstellen', 'neu', 'erinnern', 'notieren',
    // Hindi
    'जोड़ो', 'बनाओ', 'याद', 'लिखो', 'काम',
    // Portuguese
    'adicionar', 'criar', 'novo', 'lembrar', 'anotar',
    // Japanese
    '追加', '作成', '新しい', '覚えて',
    // Chinese
    '添加', '创建', '新建', '记住',
    // Arabic
    'أضف', 'أنشئ', 'جديد', 'تذكر',
    // Italian
    'aggiungi', 'crea', 'nuovo', 'ricorda', 'nota',
    // Russian
    'добавить', 'создать', 'новый', 'запомнить',
  ];

  static const _completeKeywords = [
    // English
    'complete', 'done', 'finish', 'finished', 'completed', 'check off',
    'mark done', 'mark complete', 'tick',
    // Spanish
    'completar', 'hecho', 'terminado', 'finalizar',
    // French
    'terminer', 'finir', 'complété', 'fait',
    // German
    'erledigt', 'fertig', 'abschließen', 'beendet',
    // Hindi
    'पूरा', 'खत्म', 'हो गया', 'समाप्त',
    // Portuguese
    'completar', 'feito', 'terminado', 'finalizar',
    // Italian
    'completare', 'fatto', 'finito',
    // Russian
    'завершить', 'готово', 'выполнено',
  ];

  static const _deleteKeywords = [
    // English
    'delete', 'remove', 'erase', 'clear', 'cancel', 'drop',
    // Spanish
    'eliminar', 'borrar', 'quitar', 'cancelar',
    // French
    'supprimer', 'effacer', 'annuler', 'retirer',
    // German
    'löschen', 'entfernen', 'stornieren', 'abbrechen',
    // Hindi
    'हटाओ', 'मिटाओ', 'रद्द',
    // Portuguese
    'excluir', 'remover', 'apagar', 'cancelar',
    // Italian
    'eliminare', 'cancellare', 'rimuovere',
    // Russian
    'удалить', 'убрать', 'отменить',
  ];

  static const _listKeywords = [
    // English
    'list', 'show', 'display', 'what are my', 'read', 'tell me',
    // Spanish
    'listar', 'mostrar', 'ver', 'leer',
    // French
    'lister', 'montrer', 'afficher', 'voir',
    // German
    'auflisten', 'zeigen', 'anzeigen',
    // Hindi
    'दिखाओ', 'बताओ', 'सूची',
    // Portuguese
    'listar', 'mostrar', 'ver',
    // Italian
    'elencare', 'mostrare', 'visualizzare',
    // Russian
    'список', 'показать', 'отобразить',
  ];

  static const _highPriorityKeywords = [
    'urgent', 'important', 'critical', 'high priority', 'asap',
    'urgente', 'importante', 'crítico', 'urgent', 'importante',
    'dringend', 'wichtig', 'kritisch',
    'जरूरी', 'महत्वपूर्ण',
    'urgente', 'importante', 'crítico',
    'срочно', 'важно',
  ];

  static const _lowPriorityKeywords = [
    'low priority', 'whenever', 'eventually', 'someday', 'minor',
    'baja prioridad', 'cuando pueda', 'algún día',
    'niedrige priorität', 'irgendwann',
    'कम महत्व', 'जब भी',
    'низкий приоритет', 'когда-нибудь',
  ];

  ParsedCommand parse(String text) {
    final lower = text.toLowerCase().trim();

    final priority = _detectPriority(lower);

    // Check for list command first (simple detection)
    if (_containsKeyword(lower, _listKeywords)) {
      return ParsedCommand(
        type: CommandType.listTasks,
        rawText: text,
        priority: priority,
      );
    }

    // Check for clear completed
    if ((lower.contains('clear') || lower.contains('remove')) &&
        (lower.contains('completed') || lower.contains('done') || lower.contains('finished'))) {
      return ParsedCommand(
        type: CommandType.clearCompleted,
        rawText: text,
        priority: priority,
      );
    }

    // Check for complete command
    if (_containsKeyword(lower, _completeKeywords)) {
      final title = _extractTaskTitle(lower, _completeKeywords);
      return ParsedCommand(
        type: CommandType.completeTask,
        taskTitle: title,
        rawText: text,
        priority: priority,
      );
    }

    // Check for delete command
    if (_containsKeyword(lower, _deleteKeywords)) {
      final title = _extractTaskTitle(lower, _deleteKeywords);
      return ParsedCommand(
        type: CommandType.deleteTask,
        taskTitle: title,
        rawText: text,
        priority: priority,
      );
    }

    // Check for add command or treat as implicit add
    if (_containsKeyword(lower, _addKeywords)) {
      final title = _extractTaskTitle(lower, _addKeywords);
      if (title != null && title.isNotEmpty) {
        return ParsedCommand(
          type: CommandType.addTask,
          taskTitle: _cleanTaskTitle(title),
          rawText: text,
          priority: priority,
        );
      }
    }

    // If no command keyword found but text is present, treat as implicit task addition
    if (lower.length > 3) {
      return ParsedCommand(
        type: CommandType.addTask,
        taskTitle: _cleanTaskTitle(text),
        rawText: text,
        priority: priority,
      );
    }

    return ParsedCommand(type: CommandType.unknown, rawText: text);
  }

  bool _containsKeyword(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  String? _extractTaskTitle(String text, List<String> keywords) {
    // Sort keywords by length descending to match longer phrases first
    final sorted = List<String>.from(keywords)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final keyword in sorted) {
      if (text.contains(keyword)) {
        final idx = text.indexOf(keyword);
        var after = text.substring(idx + keyword.length).trim();

        // Remove leading articles/connectors
        after = _removeLeadingConnectors(after);

        // Remove trailing priority keywords
        after = _removePriorityKeywords(after);

        if (after.isNotEmpty) return after;
      }
    }
    return text;
  }

  String _removeLeadingConnectors(String text) {
    final connectors = [
      'a ', 'an ', 'the ', 'to ', 'for ', 'me to ',
      'un ', 'una ', 'el ', 'la ',
      'ein ', 'eine ', 'der ', 'die ', 'das ',
    ];
    var result = text;
    for (final c in connectors) {
      if (result.startsWith(c)) {
        result = result.substring(c.length);
        break;
      }
    }
    return result;
  }

  String _removePriorityKeywords(String text) {
    final allPriority = [..._highPriorityKeywords, ..._lowPriorityKeywords];
    var result = text;
    for (final kw in allPriority) {
      result = result.replaceAll(kw, '').trim();
    }
    return result;
  }

  String _cleanTaskTitle(String title) {
    // Capitalize first letter
    if (title.isEmpty) return title;
    return title[0].toUpperCase() + title.substring(1);
  }

  Priority _detectPriority(String text) {
    if (_containsKeyword(text, _highPriorityKeywords)) return Priority.high;
    if (_containsKeyword(text, _lowPriorityKeywords)) return Priority.low;
    return Priority.medium;
  }
}
