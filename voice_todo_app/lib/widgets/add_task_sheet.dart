import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../theme/app_theme.dart';
import 'reminder_picker.dart';

class AddTaskSheet extends StatefulWidget {
  final Function(String title, Priority priority, DateTime? reminderAt,
      String reminderFrequency) onAdd;

  const AddTaskSheet({super.key, required this.onAdd});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _controller = TextEditingController();
  Priority _priority = Priority.medium;
  final _focusNode = FocusNode();
  String _reminderFrequency = 'none';
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickReminder() async {
    final result = await showReminderPicker(context);
    if (result != null) {
      setState(() {
        _reminderFrequency = result.frequency;
        _reminderAt = reminderAtForFrequency(result.frequency);
      });
    }
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    widget.onAdd(title, _priority, _reminderAt, _reminderFrequency);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'New Task',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF252535),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 16),
          const Text(
            'Priority',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: Priority.values.map((p) {
              final isSelected = _priority == p;
              final color = AppTheme.priorityColor(p);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _priority = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.2)
                          : const Color(0xFF252535),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? color : Colors.white12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      AppTheme.priorityLabel(p),
                      style: TextStyle(
                        color: isSelected ? color : Colors.white38,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Reminder row
          GestureDetector(
            onTap: _pickReminder,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF252535),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _reminderFrequency != 'none'
                      ? AppTheme.primaryColor.withOpacity(0.5)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _reminderFrequency != 'none'
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: _reminderFrequency != 'none'
                        ? AppTheme.primaryColor
                        : Colors.white38,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _reminderLabel(),
                      style: TextStyle(
                        color: _reminderFrequency != 'none'
                            ? Colors.white
                            : Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.white24, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Add Task',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _reminderLabel() {
    return switch (_reminderFrequency) {
      'none' => 'No reminder',
      '30min' => 'Remind in 30 minutes',
      '1hr' => 'Remind in 1 hour',
      '3hr' => 'Remind in 3 hours',
      'daily' => 'Remind daily',
      'weekly' => 'Remind weekly',
      _ => 'No reminder',
    };
  }
}
