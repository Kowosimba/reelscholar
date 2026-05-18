import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/voice_models.dart';
import '../services/voice_call_service.dart';

class VoiceCallProvider extends ChangeNotifier {
  final VoiceCallService _service;
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  VoiceCallProvider({VoiceCallService? service})
      : _service = service ?? VoiceCallService();

  CallState _state = CallState.idle;
  CallState get state => _state;

  String _callId = '';
  String get callId => _callId;

  String _topicTitle = '';
  String get topicTitle => _topicTitle;

  String _interimTranscript = '';
  String get interimTranscript => _interimTranscript;

  String _currentReply = '';
  String get currentReply => _currentReply;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _muted = false;
  bool get muted => _muted;

  int _turnCount = 0;
  int get turnCount => _turnCount;

  VoiceProgress? _progress;
  VoiceProgress? get progress => _progress;

  VoiceQuota? _quota;
  VoiceQuota? get quota => _quota;

  final List<CallTranscriptLine> _transcript = [];
  List<CallTranscriptLine> get transcript => List.unmodifiable(_transcript);

  DateTime? _startedAt;
  int get durationSeconds => _startedAt == null
      ? 0
      : DateTime.now().difference(_startedAt!).inSeconds;

  Timer? _silenceTimer;
  bool _ready = false;

  Future<bool> initialize() async {
    if (_ready) return true;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      _setError('Microphone permission denied');
      return false;
    }

    final available = await _stt.initialize(
      onStatus: _onSttStatus,
      onError: (e) {
        final msg = e.errorMsg;
        if (msg == 'error_no_match' || msg == 'error_speech_timeout') {
          // No speech detected — just wait quietly; user can tap mic to retry
          if (_state == CallState.listening) _setState(CallState.paused);
        } else if (msg == 'error_recognizer_busy') {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (_state == CallState.listening) _startListening();
          });
        } else if (msg != 'error_client') {
          // error_client fires on normal stop(); ignore it
          _setError('Mic error: $msg. Tap to retry.');
        }
      },
    );

    if (!available) {
      _setError('Speech recognition not available on this device');
      return false;
    }

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.9);
    await _tts.setPitch(1.08);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);

    // Try to select a Google neural voice for a more natural sound
    try {
      final voices = await _tts.getVoices as List?;
      if (voices != null) {
        final preferred = voices.firstWhere(
          (v) =>
              (v['locale'] as String?)?.startsWith('en-US') == true &&
              (v['name'] as String?)?.toLowerCase().contains('google') == true,
          orElse: () => null,
        );
        if (preferred != null) {
          await _tts.setVoice({
            'name': preferred['name'] as String,
            'locale': preferred['locale'] as String,
          });
        }
      }
    } catch (_) {}

    _tts.setCompletionHandler(() async {
      if (_state == CallState.speaking && !_muted) {
        // Small delay so audio focus fully transfers back before STT starts
        await Future.delayed(const Duration(milliseconds: 150));
        _startListening();
      }
    });

    _ready = true;
    return true;
  }

  Future<void> startCall(String moduleId) async {
    if (!await initialize()) return;

    _setState(CallState.connecting);
    _transcript.clear();
    _turnCount = 0;
    _startedAt = DateTime.now();

    try {
      final session = await _service.startCall(moduleId);
      _callId = session.callId;
      _topicTitle = session.topicTitle;
      _quota = session.quota;

      _currentReply = session.openingLine;
      _transcript.add(CallTranscriptLine(
        text: session.openingLine,
        isUser: false,
        at: DateTime.now(),
      ));
      _setState(CallState.speaking);
      await _tts.speak(session.openingLine);
    } on VoiceQuotaException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _startListening() async {
    if (_muted || _state == CallState.ended) return;

    _interimTranscript = '';
    _setState(CallState.listening);

    try {
      await _stt.listen(
        onResult: (result) {
          _interimTranscript = result.recognizedWords;
          notifyListeners();

          if (result.finalResult) {
            _silenceTimer?.cancel();
            _onSpeechFinal(result.recognizedWords);
          } else {
            _silenceTimer?.cancel();
            _silenceTimer = Timer(const Duration(seconds: 2), () {
              if (_state == CallState.listening &&
                  _interimTranscript.trim().isNotEmpty) {
                _stt.stop();
                _onSpeechFinal(_interimTranscript);
              }
            });
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      _setError('Could not start microphone. Tap to retry.');
    }
  }

  void _onSpeechFinal(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      if (!_muted) _startListening();
      return;
    }

    _transcript.add(CallTranscriptLine(
      text: clean,
      isUser: true,
      at: DateTime.now(),
    ));
    _interimTranscript = '';
    _setState(CallState.thinking);

    try {
      final result = await _service.sendTurn(_callId, clean);
      _turnCount = result.turnCount;
      _progress = result.progress;
      _currentReply = result.replyText;

      _transcript.add(CallTranscriptLine(
        text: result.replyText,
        isUser: false,
        at: DateTime.now(),
      ));

      _setState(CallState.speaking);
      await _tts.speak(result.replyText);
    } on VoiceQuotaException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Network hiccup. Tap the mic to try again.');
      _setState(CallState.listening);
    }
  }

  Future<void> tapToTalk() async {
    if (_state == CallState.speaking) {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (_state == CallState.listening) {
      await _stt.stop();
      _setState(CallState.paused);
      return;
    }
    if (!_muted) _startListening();
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    if (_muted) {
      await _stt.stop();
      await _tts.stop();
      _setState(CallState.paused);
    } else {
      if (_state == CallState.paused) _startListening();
    }
    notifyListeners();
  }

  Future<void> endCall() async {
    _silenceTimer?.cancel();
    await _stt.stop();
    await _tts.stop();

    final duration = durationSeconds;
    _setState(CallState.ended);

    if (_callId.isNotEmpty) {
      try {
        await _service.endCall(_callId, duration);
      } catch (e) {
        debugPrint('Failed to mark call ended: $e');
      }
    }
  }

  void _onSttStatus(String status) {
    // STT engine stopped — handled by onResult
  }

  void _setState(CallState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _setState(CallState.error);
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}
