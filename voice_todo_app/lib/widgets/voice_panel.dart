import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import 'voice_orb.dart';

class VoicePanel extends StatelessWidget {
  final VoiceService voiceService;
  final String? lastFeedback;

  const VoicePanel({
    super.key,
    required this.voiceService,
    this.lastFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF252535),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mic, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Voice Control',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _WakeWordToggle(voiceService: voiceService),
              const SizedBox(width: 8),
              _AlwaysListeningToggle(voiceService: voiceService),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              VoiceOrb(
                voiceService: voiceService,
                onTap: _handleOrbTap,
              ),
              const SizedBox(width: 16),
              Expanded(child: _TranscriptDisplay(voiceService: voiceService)),
            ],
          ),
          if (lastFeedback != null && lastFeedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _FeedbackBanner(text: lastFeedback!),
          ],
          const SizedBox(height: 12),
          _VoiceHints(voiceService: voiceService),
        ],
      ),
    );
  }

  void _handleOrbTap() {
    if (voiceService.isAlwaysListening) {
      voiceService.toggleAlwaysListening();
    } else if (voiceService.isListening) {
      voiceService.cancelListening();
    } else {
      voiceService.startListening();
    }
  }
}

class _WakeWordToggle extends StatelessWidget {
  final VoiceService voiceService;
  const _WakeWordToggle({required this.voiceService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: voiceService,
      builder: (context, _) {
        final required = voiceService.requireWakeWord;
        return GestureDetector(
          onTap: () => voiceService.setRequireWakeWord(!required),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: required
                  ? const Color(0xFF6C63FF).withOpacity(0.2)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: required
                    ? const Color(0xFF6C63FF)
                    : Colors.white24,
                width: 1,
              ),
            ),
            child: Text(
              required ? 'Tippidi' : 'Free',
              style: TextStyle(
                fontSize: 10,
                color:
                    required ? const Color(0xFF6C63FF) : Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AlwaysListeningToggle extends StatelessWidget {
  final VoiceService voiceService;
  const _AlwaysListeningToggle({required this.voiceService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: voiceService,
      builder: (context, _) {
        final isAlways = voiceService.isAlwaysListening;
        return GestureDetector(
          onTap: () => voiceService.toggleAlwaysListening(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isAlways
                  ? AppTheme.listeningColor.withOpacity(0.2)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAlways
                    ? AppTheme.listeningColor
                    : Colors.white24,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAlways ? Icons.hearing : Icons.hearing_disabled,
                  size: 13,
                  color: isAlways
                      ? AppTheme.listeningColor
                      : Colors.white38,
                ),
                const SizedBox(width: 5),
                Text(
                  isAlways ? 'Always On' : 'Always Off',
                  style: TextStyle(
                    fontSize: 11,
                    color: isAlways
                        ? AppTheme.listeningColor
                        : Colors.white38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TranscriptDisplay extends StatelessWidget {
  final VoiceService voiceService;
  const _TranscriptDisplay({required this.voiceService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: voiceService,
      builder: (context, _) {
        final current = voiceService.currentWords;
        final last = voiceService.lastWords;
        final status = voiceService.status;

        String displayText;
        Color textColor;
        String statusLabel;

        switch (status) {
          case VoiceStatus.listening:
            displayText = current.isNotEmpty ? current : 'Listening...';
            textColor = Colors.white;
            statusLabel = 'Listening';
            break;
          case VoiceStatus.processing:
            displayText = last;
            textColor = AppTheme.primaryColor;
            statusLabel = 'Processing';
            break;
          case VoiceStatus.error:
            displayText = voiceService.errorMessage;
            textColor = AppTheme.errorColor;
            statusLabel = 'Error';
            break;
          case VoiceStatus.unavailable:
            displayText = 'Microphone unavailable';
            textColor = Colors.white38;
            statusLabel = 'Unavailable';
            break;
          default:
            displayText = last.isNotEmpty ? last : 'Tap mic to speak';
            textColor = Colors.white54;
            statusLabel = 'Ready';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusDotColor(status),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusDotColor(status),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                displayText,
                key: ValueKey(displayText),
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontStyle: status == VoiceStatus.listening
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Color _statusDotColor(VoiceStatus status) {
    switch (status) {
      case VoiceStatus.listening:
        return AppTheme.listeningColor;
      case VoiceStatus.processing:
        return AppTheme.primaryColor;
      case VoiceStatus.error:
        return AppTheme.errorColor;
      default:
        return Colors.white38;
    }
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String text;
  const _FeedbackBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome,
              size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceHints extends StatelessWidget {
  final VoiceService voiceService;
  const _VoiceHints({required this.voiceService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: voiceService,
      builder: (context, _) {
        final prefix = voiceService.requireWakeWord ? '"Tippidi ' : '"';
        final hints = [
          '${prefix}add buy groceries"',
          '${prefix}complete meeting"',
          '${prefix}delete task"',
        ];
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: hints
              .map((hint) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hint,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
