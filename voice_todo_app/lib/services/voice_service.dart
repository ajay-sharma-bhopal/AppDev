import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'geolocation_service.dart';

enum VoiceStatus {
  uninitialized,
  ready,
  listening,
  processing,
  error,
  unavailable,
}

// Known STT variants for the wake word "Tippidi"
const _wakeWordVariants = [
  'tippidi',
  'tipidi',
  'tippidee',
  'tipidee',
  'tipped',
  'teppidi',
  'titipidi',
  'tippe di',
  'tipi di',
];

class VoiceService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final GeoService _geo = GeoService();

  VoiceStatus _status = VoiceStatus.uninitialized;
  String _lastWords = '';
  String _currentWords = '';
  String _errorMessage = '';
  bool _isAlwaysListening = false;
  bool _requireWakeWord = true;
  List<LocaleName> _availableLocales = [];
  LocaleName? _selectedLocale;

  Function(String)? onCommandReceived;

  VoiceStatus get status => _status;
  String get lastWords => _lastWords;
  String get currentWords => _currentWords;
  String get errorMessage => _errorMessage;
  bool get isListening => _status == VoiceStatus.listening;
  bool get isAlwaysListening => _isAlwaysListening;
  bool get requireWakeWord => _requireWakeWord;
  List<LocaleName> get availableLocales => _availableLocales;
  LocaleName? get selectedLocale => _selectedLocale;
  bool get isAvailable => _status != VoiceStatus.unavailable;

  Future<bool> initialize() async {
    try {
      final available = await _stt.initialize(
        onError: _onSttError,
        onStatus: _onSttStatus,
        debugLogging: false,
      );

      if (available) {
        _availableLocales = await _stt.locales();
        // Try to detect locale via IP geolocation first
        await _applyGeoLocale();
        _status = VoiceStatus.ready;
      } else {
        _status = VoiceStatus.unavailable;
      }

      await _initTts();
      notifyListeners();
      return available;
    } catch (e) {
      _status = VoiceStatus.unavailable;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _applyGeoLocale() async {
    if (_availableLocales.isEmpty) return;
    final localeId = await _geo.detectLocale();
    if (localeId == null) {
      _selectedLocale = _availableLocales.first;
      return;
    }
    // Find exact match or best prefix match (e.g. 'hi-IN' → 'hi_IN')
    final normalized = localeId.replaceAll('-', '_').toLowerCase();
    final match = _availableLocales.where((l) {
      return l.localeId.toLowerCase() == normalized ||
          l.localeId.toLowerCase().startsWith(normalized.split('_').first);
    }).firstOrNull;
    _selectedLocale = match ?? _availableLocales.first;
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(
        _selectedLocale?.localeId.replaceAll('_', '-') ?? 'en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> startListening() async {
    if (_status == VoiceStatus.unavailable ||
        _status == VoiceStatus.uninitialized) return;
    if (_stt.isListening) return;

    _currentWords = '';
    _status = VoiceStatus.listening;
    notifyListeners();

    await _stt.listen(
      onResult: _onSttResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: _selectedLocale?.localeId,
      cancelOnError: false,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    _isAlwaysListening = false;
    await _stt.stop();
    _status = VoiceStatus.ready;
    notifyListeners();
  }

  Future<void> toggleAlwaysListening() async {
    _isAlwaysListening = !_isAlwaysListening;
    if (_isAlwaysListening) {
      await startListening();
    } else {
      await stopListening();
    }
  }

  Future<void> cancelListening() async {
    await _stt.cancel();
    _status = VoiceStatus.ready;
    notifyListeners();
  }

  void setLocale(LocaleName locale) {
    _selectedLocale = locale;
    notifyListeners();
  }

  void setRequireWakeWord(bool value) {
    _requireWakeWord = value;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> speakTaskAdded(String taskTitle) async {
    await speak('Task added: $taskTitle');
  }

  Future<void> speakPendingAdd(String taskTitle) async {
    await speak('Confirm: $taskTitle in 5 seconds');
  }

  Future<void> speakTaskCompleted(String taskTitle) async {
    await speak('Task completed: $taskTitle');
  }

  Future<void> speakTaskDeleted(String taskTitle) async {
    await speak('Task deleted: $taskTitle');
  }

  Future<void> speakNoTaskFound() async {
    await speak('No matching task found');
  }

  void _onSttResult(SpeechRecognitionResult result) {
    _currentWords = result.recognizedWords;
    notifyListeners();

    if (result.finalResult && result.recognizedWords.isNotEmpty) {
      final raw = result.recognizedWords;
      final stripped = _stripWakeWord(raw.toLowerCase().trim());

      // In always-listening mode, require the wake word prefix
      if (_isAlwaysListening && _requireWakeWord && stripped == null) {
        _status = VoiceStatus.ready;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_isAlwaysListening) startListening();
        });
        return;
      }

      final command = stripped ?? raw;
      _lastWords = raw;
      _status = VoiceStatus.processing;
      notifyListeners();

      onCommandReceived?.call(command);

      if (_isAlwaysListening) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isAlwaysListening) {
            _status = VoiceStatus.ready;
            startListening();
          }
        });
      } else {
        _status = VoiceStatus.ready;
        notifyListeners();
      }
    }
  }

  /// Returns the transcript with the wake word stripped, or null if no wake
  /// word was found (meaning the utterance should be ignored in wake-word mode).
  String? _stripWakeWord(String lower) {
    for (final variant in _wakeWordVariants) {
      if (lower.startsWith(variant)) {
        return lower.substring(variant.length).trim();
      }
    }
    return null;
  }

  void _onSttError(SpeechRecognitionError error) {
    if (_isAlwaysListening &&
        (error.errorMsg == 'error_no_match' ||
            error.errorMsg == 'error_speech_timeout')) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_isAlwaysListening) startListening();
      });
      return;
    }
    _errorMessage = error.errorMsg;
    _status = VoiceStatus.error;
    notifyListeners();
  }

  void _onSttStatus(String status) {
    if (status == 'notListening' && _isAlwaysListening) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_isAlwaysListening && !_stt.isListening) {
          startListening();
        }
      });
    }
  }

  @override
  void dispose() {
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }
}
