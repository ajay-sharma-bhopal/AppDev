import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class PendingAddBanner extends StatelessWidget {
  const PendingAddBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, _) {
        final pending = provider.pendingAdd;
        if (pending == null) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.15),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _CountdownRing(seconds: provider.pendingSecondsLeft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saving task in…',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pending.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                    onPressed: provider.cancelPendingAdd,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Reminder frequency selector
              const Text(
                'Set reminder?',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 6),
              _ReminderQuickPick(provider: provider),

              const SizedBox(height: 10),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: provider.cancelPendingAdd,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: provider.confirmPendingAddNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child:
                          const Text('Add Now', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CountdownRing extends StatelessWidget {
  final int seconds;
  const _CountdownRing({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: seconds / 5.0,
            strokeWidth: 3,
            backgroundColor: Colors.white12,
            valueColor:
                const AlwaysStoppedAnimation(AppTheme.primaryColor),
          ),
          Text(
            '$seconds',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderQuickPick extends StatelessWidget {
  final TodoProvider provider;
  const _ReminderQuickPick({required this.provider});

  static const _options = [
    ('none', 'None'),
    ('30min', '30 min'),
    ('1hr', '1 hr'),
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
  ];

  DateTime? _reminderAt(String freq) {
    final now = DateTime.now();
    return switch (freq) {
      '30min' => now.add(const Duration(minutes: 30)),
      '1hr' => now.add(const Duration(hours: 1)),
      'daily' => now.add(const Duration(days: 1)),
      'weekly' => now.add(const Duration(days: 7)),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final selected = provider.pendingAdd?.reminderFrequency ?? 'none';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _options.map((opt) {
          final freq = opt.$1;
          final label = opt.$2;
          final isSelected = selected == freq;
          return GestureDetector(
            onTap: () => provider.setPendingReminder(freq, _reminderAt(freq)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white54,
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
