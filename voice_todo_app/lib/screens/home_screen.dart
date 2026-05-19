import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/supabase_config.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_panel.dart';
import '../widgets/todo_tile.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/language_picker.dart';
import '../widgets/pending_add_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          appBar: _buildAppBar(context, provider),
          body: _buildBody(context, provider),
          floatingActionButton: _buildFab(context, provider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, TodoProvider provider) {
    return AppBar(
      backgroundColor: AppTheme.darkBg,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tippidi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            '${provider.activeCount} task${provider.activeCount != 1 ? 's' : ''} remaining',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        LanguagePickerButton(voiceService: provider.voiceService),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          onPressed: () => _showOptions(context, provider),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, TodoProvider provider) {
    return Column(
      children: [
        // Voice panel at top
        VoicePanel(
          voiceService: provider.voiceService,
          lastFeedback: provider.lastCommandFeedback,
        ),

        // Pending-add countdown banner
        const PendingAddBanner(),

        // Filter chips
        _FilterBar(provider: provider),

        const SizedBox(height: 4),

        // Task list
        Expanded(
          child: provider.todos.isEmpty
              ? _EmptyState(filter: provider.filterMode)
              : _TaskList(provider: provider),
        ),
      ],
    );
  }

  Widget _buildFab(BuildContext context, TodoProvider provider) {
    return FloatingActionButton(
      onPressed: () => _showAddSheet(context, provider),
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showAddSheet(BuildContext context, TodoProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        onAdd: (title, priority, reminderAt, reminderFrequency) =>
            provider.addTaskManually(
          title,
          priority: priority,
          reminderAt: reminderAt,
          reminderFrequency: reminderFrequency,
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, TodoProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const Icon(Icons.done_all, color: Colors.white70),
              title: const Text('Clear completed',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                '${provider.completedCount} completed tasks',
                style: const TextStyle(color: Colors.white38),
              ),
              onTap: () {
                Navigator.pop(context);
                provider.processVoiceCommand('clear completed tasks');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline,
                  color: Colors.white70),
              title: const Text('Voice commands',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showVoiceHelp(context);
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Colors.white54),
              title: const Text('Sign out',
                  style: TextStyle(color: Colors.white70)),
              subtitle: Text(
                supabase.auth.currentUser?.email ?? '',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                context.read<TodoProvider>().signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showVoiceHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Voice Commands',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._helpItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item[0],
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item[1],
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              const Text(
                'Say "Tippidi" first, then your command in any language!',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        AppTheme.primaryColor.withOpacity(0.15),
                  ),
                  child: const Text('Got it',
                      style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _helpItems = [
    ['ADD', '"Tippidi add buy groceries" / "Tippidi new meeting notes"'],
    ['COMPLETE', '"Tippidi complete buy groceries"'],
    ['DELETE', '"Tippidi delete buy groceries"'],
    ['LIST', '"Tippidi show my tasks"'],
    ['CLEAR', '"Tippidi clear completed tasks"'],
    ['PRIORITY', 'Add "urgent" or "important" for high priority'],
  ];
}

class _FilterBar extends StatelessWidget {
  final TodoProvider provider;
  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _FilterChip(
            label: 'All (${provider.allTodos.length})',
            isSelected: provider.filterMode == 'all',
            onTap: () => provider.setFilter('all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Active (${provider.activeCount})',
            isSelected: provider.filterMode == 'active',
            onTap: () => provider.setFilter('active'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Done (${provider.completedCount})',
            isSelected: provider.filterMode == 'completed',
            onTap: () => provider.setFilter('completed'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : const Color(0xFF252535),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final TodoProvider provider;
  const _TaskList({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: provider.todos.length,
      itemBuilder: (context, index) {
        final todo = provider.todos[index];
        return TodoTile(
          todo: todo,
          onToggle: () => provider.toggleTask(todo.id),
          onDelete: () => provider.deleteTask(todo.id),
          onEdit: () =>
              _showEditDialog(context, provider, todo.id, todo.title),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, TodoProvider provider,
      String id, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Task',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF252535),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.updateTask(id, ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (filter) {
      'active' =>
        (Icons.check_circle_outline, 'All done!', 'No active tasks. Great job!'),
      'completed' => (
          Icons.hourglass_empty,
          'No completed tasks',
          'Complete a task to see it here'
        ),
      _ => (
          Icons.mic_none,
          'No tasks yet',
          'Say "Tippidi add [task]" or tap + to get started'
        ),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle,
              style:
                  const TextStyle(color: Colors.white24, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
