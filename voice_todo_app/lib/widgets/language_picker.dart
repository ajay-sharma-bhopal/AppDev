import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';

class LanguagePickerButton extends StatelessWidget {
  final VoiceService voiceService;

  const LanguagePickerButton({super.key, required this.voiceService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: voiceService,
      builder: (context, _) {
        if (voiceService.availableLocales.isEmpty) return const SizedBox.shrink();
        final selected = voiceService.selectedLocale;
        return TextButton.icon(
          onPressed: () => _showPicker(context),
          icon: const Icon(Icons.language, size: 16, color: AppTheme.primaryColor),
          label: Text(
            selected != null ? _shortLocale(selected) : 'Auto',
            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LocalePicker(voiceService: voiceService),
    );
  }

  String _shortLocale(LocaleName locale) {
    final parts = locale.localeId.split('-');
    if (parts.length >= 2) return parts[0].toUpperCase();
    return locale.localeId.substring(0, 2).toUpperCase();
  }
}

class _LocalePicker extends StatefulWidget {
  final VoiceService voiceService;
  const _LocalePicker({required this.voiceService});

  @override
  State<_LocalePicker> createState() => _LocalePickerState();
}

class _LocalePickerState extends State<_LocalePicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final locales = widget.voiceService.availableLocales
        .where((l) =>
            l.name.toLowerCase().contains(_search.toLowerCase()) ||
            l.localeId.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Column(
      children: [
        // Handle
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
        const Text(
          'Select Language',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search languages...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF252535),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: locales.length,
            itemBuilder: (context, i) {
              final locale = locales[i];
              final isSelected =
                  widget.voiceService.selectedLocale?.localeId == locale.localeId;
              return ListTile(
                title: Text(
                  locale.name,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  locale.localeId,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  widget.voiceService.setLocale(locale);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
