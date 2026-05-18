import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';

class VoiceOrb extends StatelessWidget {
  final VoiceService voiceService;
  final VoidCallback onTap;

  const VoiceOrb({
    super.key,
    required this.voiceService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: voiceService,
      builder: (context, _) {
        final status = voiceService.status;
        final isListening = status == VoiceStatus.listening;
        final isAlways = voiceService.isAlwaysListening;
        final color = _statusColor(status, isAlways);

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring (only when listening)
              if (isListening)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.15),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(begin: const Offset(1, 1), end: const Offset(1.4, 1.4), duration: 1200.ms)
                    .fadeOut(begin: 1, duration: 1200.ms),

              // Middle ring
              if (isListening)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(begin: const Offset(1, 1), end: const Offset(1.25, 1.25), duration: 1200.ms, delay: 200.ms)
                    .fadeOut(begin: 0.8, duration: 1200.ms, delay: 200.ms),

              // Core orb
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.9),
                      color,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: isListening ? 20 : 8,
                      spreadRadius: isListening ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _statusIcon(status),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(VoiceStatus status, bool isAlways) {
    if (isAlways && status == VoiceStatus.listening) return AppTheme.listeningColor;
    switch (status) {
      case VoiceStatus.listening:
        return AppTheme.listeningColor;
      case VoiceStatus.processing:
        return AppTheme.primaryColor;
      case VoiceStatus.error:
        return AppTheme.errorColor;
      case VoiceStatus.unavailable:
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _statusIcon(VoiceStatus status) {
    switch (status) {
      case VoiceStatus.listening:
        return Icons.mic;
      case VoiceStatus.processing:
        return Icons.auto_awesome;
      case VoiceStatus.error:
        return Icons.mic_off;
      case VoiceStatus.unavailable:
        return Icons.mic_none;
      default:
        return Icons.mic_none;
    }
  }
}
