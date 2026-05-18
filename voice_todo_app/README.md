# VoiceTodo — Voice-Enabled TODO App

A Flutter-based cross-platform TODO app for **Android and iOS** that listens to your voice and understands commands in multiple languages.

## Features

- **Always-listening mode** — toggle to keep the mic active continuously
- **Multi-language support** — understands English, Spanish, French, German, Hindi, Portuguese, Japanese, Chinese, Arabic, Italian, Russian, and more (powered by the device's native speech engine)
- **Smart command parsing** — natural language commands without rigid syntax
- **TTS feedback** — app speaks back confirmations after each command
- **Priority system** — High / Medium / Low with visual color coding
- **Filter views** — All / Active / Completed
- **Swipe to delete**, tap to complete, long press to edit
- **Local persistence** — tasks saved between sessions

## Voice Commands

| Command | Example |
|---------|---------|
| Add task | `"Add buy groceries"` / `"Agregar comprar leche"` |
| Complete task | `"Complete buy groceries"` / `"Done with meeting"` |
| Delete task | `"Delete the meeting"` / `"Eliminar tarea"` |
| List tasks | `"Show my tasks"` / `"Mostrar tareas"` |
| Clear done | `"Clear completed tasks"` |
| Priority | Add `"urgent"` / `"important"` for High priority |

Plain phrases (without command keywords) are automatically treated as task additions.

## Architecture

```
lib/
├── main.dart                  # Entry point, splash gate
├── models/
│   └── todo_item.dart         # TodoItem model with priority & persistence
├── providers/
│   └── todo_provider.dart     # State management (ChangeNotifier)
├── services/
│   ├── voice_service.dart     # STT + TTS wrapper, always-listening loop
│   └── command_parser.dart    # Multi-language keyword-based command parser
├── screens/
│   └── home_screen.dart       # Main screen, filter bar, task list
├── widgets/
│   ├── voice_panel.dart       # Voice status UI panel
│   ├── voice_orb.dart         # Animated mic orb with pulse rings
│   ├── todo_tile.dart         # Task list item with swipe-to-delete
│   ├── add_task_sheet.dart    # Manual task add bottom sheet
│   └── language_picker.dart   # Language selector bottom sheet
└── theme/
    └── app_theme.dart         # Dark theme with color constants
```

## Setup

### Prerequisites
- Flutter SDK ≥ 3.13.0
- Dart SDK ≥ 3.1.0

### Android
- Min SDK: 21 (Android 5.0 Lollipop)
- Requires `RECORD_AUDIO` permission (requested at runtime)
- Uses Google Speech Recognition service

### iOS
- iOS 12+
- Requires `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` in Info.plist (already configured)
- Uses Apple's on-device Speech framework

### Run
```bash
cd voice_todo_app
flutter pub get
flutter run
```

## How Always-Listening Works

1. `VoiceService.toggleAlwaysListening()` sets `_isAlwaysListening = true`
2. After each recognized phrase, if still in always-listening mode, `startListening()` is called again after 500ms
3. On `error_no_match` or `error_speech_timeout`, the service restarts automatically
4. Battery note: continuous listening uses the device's speech recognition engine which may consume battery

## Extending Language Support

The `CommandParser` uses keyword lists per language. To add a new language:
1. Add keywords to the `_addKeywords`, `_completeKeywords`, etc. lists in `command_parser.dart`
2. The speech engine handles audio-to-text; the parser handles intent detection
3. Select the target language in the Language Picker in the app's toolbar
