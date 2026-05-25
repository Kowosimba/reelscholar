import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/voice_models.dart';
import '../services/voice_call_service.dart';

class VoiceCallProvider extends ChangeNotifier with WidgetsBindingObserver {
  final VoiceCallService _service;
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  VoiceCallProvider({VoiceCallService? service})
      : _service = service ?? VoiceCallService() {
    WidgetsBinding.instance.addObserver(this);
  }

  // ── Core state ────────────────────────────────────────────────────────────
  CallState _state = CallState.idle;
  CallState get state => _state;

  String _callId = '';
  String get callId => _callId;

  String _topicTitle = '';
  String get topicTitle => _topicTitle;

  bool _isResumed = false;
  bool get isResumed => _isResumed;

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

  bool _showQuizBanner = false;
  bool get showQuizBanner => _showQuizBanner;

  // Non-null when a topic just advanced; consumed by the UI for a toast.
  String? _topicAdvancedTitle;
  String? get topicAdvancedTitle => _topicAdvancedTitle;

  VoiceEndSummary? _endSummary;
  VoiceEndSummary? get endSummary => _endSummary;

  final List<CallTranscriptLine> _transcript = [];
  List<CallTranscriptLine> get transcript => List.unmodifiable(_transcript);

  DateTime? _startedAt;
  int get durationSeconds => _startedAt == null
      ? 0
      : DateTime.now().difference(_startedAt!).inSeconds;

  Timer? _silenceTimer;
  Timer? _rateLimitTimer;
  bool _ready = false;

  // ── AppLifecycle ─────────────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_callId.isNotEmpty &&
          _state != CallState.ended &&
          _state != CallState.idle) {
        endCall();
      }
    }
  }

  // ── Initialization ────────────────────────────────────────────────────────
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
          if (_state == CallState.listening) _setState(CallState.paused);
        } else if (msg == 'error_recognizer_busy') {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (_state == CallState.listening) _startListening();
          });
        } else if (msg != 'error_client') {
          _setError('Mic error: $msg. Tap to retry.');
        }
      },
    );

    if (!available) {
      _setError('Speech recognition not available on this device');
      return false;
    }

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.55);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);

    try {
      final voices = await _tts.getVoices as List?;
      if (voices != null) {
        final preferred = voices.firstWhere(
          (v) =>
              (v['locale'] as String?)?.startsWith('en') == true &&
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
        await Future.delayed(const Duration(milliseconds: 150));
        _startListening();
      }
    });

    _ready = true;
    return true;
  }

  // ── Start call ────────────────────────────────────────────────────────────
  Future<void> startCall(String moduleId) async {
    if (!await initialize()) return;

    _setState(CallState.connecting);
    _transcript.clear();
    _turnCount = 0;
    _startedAt = DateTime.now();
    _showQuizBanner = false;
    _topicAdvancedTitle = null;
    _endSummary = null;

    try {
      final session = await _service.startCall(moduleId);
      _callId = session.callId;
      _topicTitle = session.topicTitle;
      _isResumed = session.isResumed;
      _progress = session.progress;
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
      final msg = e.toString().replaceFirst('Exception: ', '');
      _setError(msg);
    }
  }

  // ── Listening ─────────────────────────────────────────────────────────────
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
        listenFor: const Duration(seconds: 15),
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

  // ── Turn loop ─────────────────────────────────────────────────────────────
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

      if (result.topicAdvanced) {
        _topicTitle = result.progress.currentTopicTitle;
        _topicAdvancedTitle = result.progress.currentTopicTitle;
      }
      if (result.progress.shouldSuggestQuiz) {
        _showQuizBanner = true;
      }

      // Update quota remaining from turn count (cap - turns used = remaining).
      // The API doesn't return quota on turns, so decrement locally.
      if (_quota != null) {
        _quota = VoiceQuota(
          usedTurns: _quota!.usedTurns + 1,
          capTurns: _quota!.capTurns,
          remainingTurns: (_quota!.remainingTurns - 1).clamp(0, _quota!.capTurns),
        );
      }

      _currentReply = result.replyText;
      _transcript.add(CallTranscriptLine(
        text: result.replyText,
        isUser: false,
        at: DateTime.now(),
      ));

      _setState(CallState.speaking);
      await _tts.speak(result.replyText);
    } on VoiceCallEndedException {
      await endCall();
      _errorMessage = 'Session ended.';
      _setState(CallState.ended);
    } on VoiceTutorUnavailableException {
      // Keep the call alive; let the student tap retry.
      _errorMessage = 'Tutor had trouble, tap to retry.';
      _setState(CallState.listening);
    } on VoiceQuotaException catch (e) {
      if (e.retryAfterSeconds > 0) {
        _errorMessage = e.message;
        _setState(CallState.paused);
        _rateLimitTimer?.cancel();
        _rateLimitTimer = Timer(Duration(seconds: e.retryAfterSeconds), () {
          if (_state == CallState.paused && !_muted) _startListening();
        });
      } else {
        _setError(e.message);
      }
    } catch (e) {
      _errorMessage = 'Network hiccup. Tap the mic to try again.';
      _setState(CallState.listening);
    }
  }

  // ── Controls ──────────────────────────────────────────────────────────────
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

  /// Clear the topicAdvancedTitle after the UI has consumed it (shown toast).
  void clearTopicAdvancedTitle() {
    _topicAdvancedTitle = null;
  }

  // ── End call ──────────────────────────────────────────────────────────────
  Future<void> endCall() async {
    if (_state == CallState.ended) return;
    _silenceTimer?.cancel();
    _rateLimitTimer?.cancel();
    await _stt.stop();
    await _tts.stop();

    final duration = durationSeconds;
    _setState(CallState.ended);

    if (_callId.isNotEmpty) {
      try {
        _endSummary = await _service.endCall(_callId, duration);
      } catch (e) {
        debugPrint('Failed to mark call ended: $e');
        // Build a local summary so the UI still shows something.
        _endSummary = VoiceEndSummary(
          callId: _callId,
          status: 'ended',
          durationSeconds: duration,
          turnCount: _turnCount,
        );
      }
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────
  void _onSttStatus(String status) {
    // Handled via onResult and onError callbacks.
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
    WidgetsBinding.instance.removeObserver(this);
    _silenceTimer?.cancel();
    _rateLimitTimer?.cancel();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}
