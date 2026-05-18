import 'package:flutter_test/flutter_test.dart';
import 'package:voice_todo_app/services/command_parser.dart';
import 'package:voice_todo_app/models/todo_item.dart';

void main() {
  final parser = CommandParser();

  group('CommandParser - English', () {
    test('parses add command', () {
      final result = parser.parse('Add buy groceries');
      expect(result.type, CommandType.addTask);
      expect(result.taskTitle, 'Buy groceries');
    });

    test('parses create command', () {
      final result = parser.parse('create new meeting notes');
      expect(result.type, CommandType.addTask);
    });

    test('parses complete command', () {
      final result = parser.parse('complete buy groceries');
      expect(result.type, CommandType.completeTask);
    });

    test('parses delete command', () {
      final result = parser.parse('delete the meeting task');
      expect(result.type, CommandType.deleteTask);
    });

    test('parses list command', () {
      final result = parser.parse('show my tasks');
      expect(result.type, CommandType.listTasks);
    });

    test('parses clear completed command', () {
      final result = parser.parse('clear completed tasks');
      expect(result.type, CommandType.clearCompleted);
    });

    test('detects high priority', () {
      final result = parser.parse('Add urgent doctor appointment');
      expect(result.type, CommandType.addTask);
      expect(result.priority, Priority.high);
    });

    test('detects low priority', () {
      final result = parser.parse('Add low priority clean garage');
      expect(result.type, CommandType.addTask);
      expect(result.priority, Priority.low);
    });

    test('implicit add for plain text', () {
      final result = parser.parse('Pick up dry cleaning');
      expect(result.type, CommandType.addTask);
      expect(result.taskTitle, 'Pick up dry cleaning');
    });
  });

  group('CommandParser - Spanish', () {
    test('parses agregar command', () {
      final result = parser.parse('agregar comprar leche');
      expect(result.type, CommandType.addTask);
    });

    test('parses completar command', () {
      final result = parser.parse('completar reunión');
      expect(result.type, CommandType.completeTask);
    });

    test('parses eliminar command', () {
      final result = parser.parse('eliminar tarea antigua');
      expect(result.type, CommandType.deleteTask);
    });
  });

  group('CommandParser - French', () {
    test('parses ajouter command', () {
      final result = parser.parse('ajouter acheter du lait');
      expect(result.type, CommandType.addTask);
    });
  });

  group('CommandParser - German', () {
    test('parses hinzufügen command', () {
      final result = parser.parse('hinzufügen milch kaufen');
      expect(result.type, CommandType.addTask);
    });
  });

  group('CommandParser - edge cases', () {
    test('returns unknown for very short input', () {
      final result = parser.parse('hi');
      expect(result.type, CommandType.unknown);
    });

    test('handles empty task title gracefully', () {
      final result = parser.parse('add');
      // Should either be unknown or add with empty/null title
      if (result.type == CommandType.addTask) {
        expect(result.taskTitle == null || result.taskTitle!.isEmpty || result.taskTitle == 'Add', true);
      }
    });
  });
}
