import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum VoiceStatus {
  uninitialized,
  ready,
  listening,
  processing,
  error,
  unavailable,
}

class VoiceService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  VoiceStatus _status = VoiceStatus.uninitialized;
  String _lastWords = '';
  String _currentWords = '';
  String _errorMessage = '';
  bool _isAlwaysListening = false;
  List<LocaleName> _availableLocales = [];
  LocaleName? _selectedLocale;

  // Callback invoked when a final recognized phrase is ready
  Function(String)? onCommandReceived;

  VoiceStatus get status => _status;
  String get lastWords => _lastWords;
  String get currentWords => _currentWords;
  String get errorMessage => _errorMessage;
  bool get isListening => _status == VoiceStatus.listening;
  bool get isAlwaysListening => _isAlwaysListening;
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
        _selectedLocale = _availableLocales.isNotEmpty
            ? _availableLocales.first
            : null;
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

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> startListening() async {
    if (_status == VoiceStatus.unavailable || _status == VoiceStatus.uninitialized) {
      return;
    }
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

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> speakTaskAdded(String taskTitle) async {
    await speak('Task added: $taskTitle');
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
      _lastWords = result.recognizedWords;
      _status = VoiceStatus.processing;
      notifyListeners();

      onCommandReceived?.call(result.recognizedWords);

      // If always-listening mode, restart after a short delay
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

  void _onSttError(SpeechRecognitionError error) {
    // Ignore no-speech errors in always-listening mode — just restart
    if (_isAlwaysListening &&
        (error.errorMsg == 'error_no_match' || error.errorMsg == 'error_speech_timeout')) {
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
