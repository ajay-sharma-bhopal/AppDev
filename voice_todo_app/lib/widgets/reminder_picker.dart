import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReminderOption {
  final String frequency;
  final String label;
  final String description;
  final IconData icon;

  const ReminderOption({
    required this.frequency,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const _reminderOptions = [
  ReminderOption(
      frequency: 'none',
      label: 'No reminder',
      description: 'Skip reminder',
      icon: Icons.notifications_off_outlined),
  ReminderOption(
      frequency: '30min',
      label: 'In 30 minutes',
      description: 'Once',
      icon: Icons.timer_outlined),
  ReminderOption(
      frequency: '1hr',
      label: 'In 1 hour',
      description: 'Once',
      icon: Icons.timer_outlined),
  ReminderOption(
      frequency: '3hr',
      label: 'In 3 hours',
      description: 'Once',
      icon: Icons.timer_outlined),
  ReminderOption(
      frequency: 'daily',
      label: 'Daily',
      description: 'Repeats every day',
      icon: Icons.repeat_outlined),
  ReminderOption(
      frequency: 'weekly',
      label: 'Weekly',
      description: 'Repeats every week',
      icon: Icons.date_range_outlined),
];

DateTime? reminderAtForFrequency(String frequency) {
  final now = DateTime.now();
  return switch (frequency) {
    '30min' => now.add(const Duration(minutes: 30)),
    '1hr' => now.add(const Duration(hours: 1)),
    '3hr' => now.add(const Duration(hours: 3)),
    'daily' => now.add(const Duration(days: 1)),
    'weekly' => now.add(const Duration(days: 7)),
    _ => null,
  };
}

/// Shows a bottom sheet for picking a reminder. Returns the selected
/// [ReminderOption] or null if dismissed.
Future<ReminderOption?> showReminderPicker(BuildContext context) {
  return showModalBottomSheet<ReminderOption>(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ReminderPickerSheet(),
  );
}

class _ReminderPickerSheet extends StatelessWidget {
  const _ReminderPickerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Set Reminder',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._reminderOptions.map((opt) => ListTile(
                leading: Icon(opt.icon, color: Colors.white54, size: 22),
                title: Text(opt.label,
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
                subtitle: Text(opt.description,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () => Navigator.pop(context, opt),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
