import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:reelscholar/models/tutor_models.dart';
import '../core/services/tutor_service.dart';

enum TutorLoadState { idle, loading, loaded, error }

class TutorProvider extends ChangeNotifier {
  final TutorService _svc = TutorService();
  final FlutterTts _tts = FlutterTts();

  // ─── Modules list ────────────────────────────────────────────────────────────
  ModulesResponse? _modulesResponse;
  TutorLoadState _modulesState = TutorLoadState.idle;
  String? _modulesError;

  // ─── Active session ──────────────────────────────────────────────────────────
  TutorModule? _activeModule;
  SessionProgress? _sessionProgress;
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isStarting = false;
  String? _chatError;
  TutorLoadState _historyState = TutorLoadState.idle;

  // ─── Flashcards ──────────────────────────────────────────────────────────────
  final Map<String, List<Flashcard>> _flashcards = {};
  TutorLoadState _flashcardsState = TutorLoadState.idle;
  int _currentCardIndex = 0;
  bool _cardFlipped = false;

  // ─── Concept map ─────────────────────────────────────────────────────────────
  final Map<String, ConceptMap> _conceptMaps = {};
  TutorLoadState _conceptMapState = TutorLoadState.idle;

  // ─── Voice lesson ────────────────────────────────────────────────────────────
  final Map<String, VoiceLesson> _voiceLessons = {};
  TutorLoadState _voiceLessonState = TutorLoadState.idle;
  int _activeSegmentIndex = 0;
  bool _voiceIsPlaying = false;
  String? _voiceModuleId;
  bool _ttsReady = false;

  // ─── Module filter ───────────────────────────────────────────────────────────
  String _moduleFilter = 'all'; // all | in_progress | completed | not_started
  String _searchQuery = '';

  // ─── Getters ─────────────────────────────────────────────────────────────────
  ModulesResponse? get modulesResponse => _modulesResponse;
  TutorLoadState get modulesState => _modulesState;
  String? get modulesError => _modulesError;

  TutorModule? get activeModule => _activeModule;
  SessionProgress? get sessionProgress => _sessionProgress;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  bool get isStarting => _isStarting;
  String? get chatError => _chatError;
  TutorLoadState get historyState => _historyState;

  TutorLoadState get flashcardsState => _flashcardsState;
  int get currentCardIndex => _currentCardIndex;
  bool get cardFlipped => _cardFlipped;

  TutorLoadState get conceptMapState => _conceptMapState;
  TutorLoadState get voiceLessonState => _voiceLessonState;
  int get activeSegmentIndex => _activeSegmentIndex;
  bool get voiceIsPlaying => _voiceIsPlaying;

  String get moduleFilter => _moduleFilter;
  String get searchQuery => _searchQuery;

  List<Flashcard> flashcardsFor(String moduleId) => _flashcards[moduleId] ?? [];
  ConceptMap? conceptMapFor(String moduleId) => _conceptMaps[moduleId];
  VoiceLesson? voiceLessonFor(String moduleId) => _voiceLessons[moduleId];

  Flashcard? get currentCard {
    final cards = flashcardsFor(_activeModule?.moduleId ?? '');
    if (cards.isEmpty) return null;
    return cards[_currentCardIndex.clamp(0, cards.length - 1)];
  }

  /// Filtered + searched current modules
  List<TutorModule> get filteredModules {
    final all = _modulesResponse?.currentModules ?? [];
    return all.where((m) {
      final matchesFilter = _moduleFilter == 'all' || m.status == _moduleFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.code.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  // ─── Load modules list ───────────────────────────────────────────────────────
  Future<void> loadModules({bool refresh = false}) async {
    if (!refresh && _modulesState == TutorLoadState.loaded) return;
    _modulesState = TutorLoadState.loading;
    _modulesError = null;
    notifyListeners();

    try {
      _modulesResponse = await _svc.getModules();
      _modulesState = TutorLoadState.loaded;
    } catch (e) {
      _modulesState = TutorLoadState.error;
      _modulesError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ─── Filter / search ─────────────────────────────────────────────────────────
  void setFilter(String filter) {
    _moduleFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ─── Start / resume session ──────────────────────────────────────────────────
  Future<bool> startSession(TutorModule module) async {
    _activeModule = module;
    _messages.clear();
    _sessionProgress = null;
    _chatError = null;
    _isStarting = true;
    notifyListeners();

    try {
      final result = await _svc.startSession(module.moduleId);
      _sessionProgress = result.progress;

      // Add welcome message from tutor
      _messages.add(ChatMessage.tutor(
        result.message,
        progress: result.progress,
      ));

      _isStarting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _chatError = e.toString().replaceFirst('Exception: ', '');
      _isStarting = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Send chat message ───────────────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _activeModule == null || _isSending) return;

    final userMsg = ChatMessage.user(text.trim());
    _messages.add(userMsg);
    _isSending = true;
    _chatError = null;
    notifyListeners();

    try {
      final resp = await _svc.chat(_activeModule!.moduleId, text.trim());
      _messages.add(ChatMessage.tutor(resp.message, progress: resp.progress));
      _sessionProgress = resp.progress;
    } catch (e) {
      _chatError = e.toString().replaceFirst('Exception: ', '');
      // Remove the user's message if sending failed
      _messages.removeLast();
    }

    _isSending = false;
    notifyListeners();
  }

  // ─── Load history ────────────────────────────────────────────────────────────
  Future<void> loadHistory(String moduleId) async {
    _historyState = TutorLoadState.loading;
    notifyListeners();

    try {
      final history = await _svc.getHistory(moduleId);
      _messages.clear();
      _messages.addAll(history);
      _historyState = TutorLoadState.loaded;
    } catch (e) {
      _historyState = TutorLoadState.error;
    }
    notifyListeners();
  }

  // ─── Reset session ───────────────────────────────────────────────────────────
  Future<void> resetSession(String moduleId) async {
    await _svc.resetSession(moduleId);
    if (_activeModule?.moduleId == moduleId) {
      _messages.clear();
      _sessionProgress = null;
    }
    notifyListeners();
  }

  // ─── Flashcards ──────────────────────────────────────────────────────────────
  Future<void> loadFlashcards(String moduleId) async {
    if (_flashcards.containsKey(moduleId)) {
      // Already loaded — just reset card state
      _currentCardIndex = 0;
      _cardFlipped = false;
      notifyListeners();
      return;
    }

    _flashcardsState = TutorLoadState.loading;
    notifyListeners();

    try {
      final cards = await _svc.getFlashcards(moduleId);
      _flashcards[moduleId] = cards;
      _currentCardIndex = 0;
      _cardFlipped = false;
      _flashcardsState = TutorLoadState.loaded;
    } catch (e) {
      _flashcardsState = TutorLoadState.error;
    }
    notifyListeners();
  }

  void flipCard() {
    _cardFlipped = !_cardFlipped;
    notifyListeners();
  }

  void markCardKnown(String moduleId) {
    final cards = _flashcards[moduleId];
    if (cards == null) return;
    final idx = _currentCardIndex.clamp(0, cards.length - 1);
    cards[idx].status = FlashcardStatus.known;
    _advanceCard(moduleId);
  }

  void markCardLearning(String moduleId) {
    final cards = _flashcards[moduleId];
    if (cards == null) return;
    final idx = _currentCardIndex.clamp(0, cards.length - 1);
    cards[idx].status = FlashcardStatus.learning;
    _advanceCard(moduleId);
  }

  void _advanceCard(String moduleId) {
    final cards = _flashcards[moduleId] ?? [];
    _cardFlipped = false;
    if (_currentCardIndex < cards.length - 1) {
      _currentCardIndex++;
    }
    notifyListeners();
  }

  void setCardIndex(int index) {
    _currentCardIndex = index;
    _cardFlipped = false;
    notifyListeners();
  }

  void resetFlashcards(String moduleId) {
    final cards = _flashcards[moduleId];
    if (cards == null) return;
    for (final card in cards) {
      card.status = FlashcardStatus.unseen;
    }
    _currentCardIndex = 0;
    _cardFlipped = false;
    notifyListeners();
  }

  // ─── Concept map ─────────────────────────────────────────────────────────────
  Future<void> loadConceptMap(String moduleId) async {
    if (_conceptMaps.containsKey(moduleId)) return;

    _conceptMapState = TutorLoadState.loading;
    notifyListeners();

    try {
      final map = await _svc.getConceptMap(moduleId);
      _conceptMaps[moduleId] = map;
      _conceptMapState = TutorLoadState.loaded;
    } catch (e) {
      _conceptMapState = TutorLoadState.error;
    }
    notifyListeners();
  }

  // ─── Voice lesson ────────────────────────────────────────────────────────────
  Future<void> _initTts() async {
    if (_ttsReady) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.88);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(_onTtsSegmentComplete);
    _tts.setCancelHandler(_onTtsStopped);
    _tts.setErrorHandler((_) => _onTtsStopped());
    _ttsReady = true;
  }

  void _onTtsSegmentComplete() {
    if (!_voiceIsPlaying || _voiceModuleId == null) return;
    final lesson = _voiceLessons[_voiceModuleId!];
    if (lesson == null) return;
    if (_activeSegmentIndex < lesson.segments.length - 1) {
      _activeSegmentIndex++;
      notifyListeners();
      _speakSegment(lesson.segments[_activeSegmentIndex].content);
    } else {
      // Reached the end — stop playing
      _voiceIsPlaying = false;
      notifyListeners();
    }
  }

  void _onTtsStopped() {
    if (_voiceIsPlaying) {
      _voiceIsPlaying = false;
      notifyListeners();
    }
  }

  Future<void> _speakSegment(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> loadVoiceLesson(String moduleId) async {
    await _stopTts();
    if (_voiceLessons.containsKey(moduleId)) {
      _activeSegmentIndex = 0;
      _voiceIsPlaying = false;
      _voiceModuleId = moduleId;
      notifyListeners();
      return;
    }

    _voiceLessonState = TutorLoadState.loading;
    notifyListeners();

    try {
      final lesson = await _svc.getVoiceLesson(moduleId);
      _voiceLessons[moduleId] = lesson;
      _activeSegmentIndex = 0;
      _voiceIsPlaying = false;
      _voiceModuleId = moduleId;
      _voiceLessonState = TutorLoadState.loaded;
    } catch (e) {
      _voiceLessonState = TutorLoadState.error;
    }
    notifyListeners();
  }

  void setActiveSegment(int index) {
    _activeSegmentIndex = index;
    if (_voiceIsPlaying && _voiceModuleId != null) {
      final lesson = _voiceLessons[_voiceModuleId!];
      if (lesson != null && index < lesson.segments.length) {
        _speakSegment(lesson.segments[index].content);
      }
    }
    notifyListeners();
  }

  Future<void> toggleVoicePlayback() async {
    await _initTts();
    if (_voiceIsPlaying) {
      await _stopTts();
    } else {
      if (_voiceModuleId == null) return;
      final lesson = _voiceLessons[_voiceModuleId!];
      if (lesson == null || lesson.segments.isEmpty) return;
      _voiceIsPlaying = true;
      notifyListeners();
      await _speakSegment(lesson.segments[_activeSegmentIndex].content);
    }
  }

  Future<void> _stopTts() async {
    await _tts.stop();
    _voiceIsPlaying = false;
    notifyListeners();
  }

  Future<void> nextSegment(String moduleId) async {
    final lesson = _voiceLessons[moduleId];
    if (lesson == null) return;
    if (_activeSegmentIndex < lesson.segments.length - 1) {
      _activeSegmentIndex++;
      notifyListeners();
      if (_voiceIsPlaying) {
        await _speakSegment(lesson.segments[_activeSegmentIndex].content);
      }
    }
  }

  Future<void> prevSegment() async {
    if (_activeSegmentIndex > 0) {
      _activeSegmentIndex--;
      notifyListeners();
      if (_voiceIsPlaying && _voiceModuleId != null) {
        final lesson = _voiceLessons[_voiceModuleId!];
        if (lesson != null) {
          await _speakSegment(lesson.segments[_activeSegmentIndex].content);
        }
      }
    }
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────────────
  @override
  Future<void> dispose() async {
    await _tts.stop();
    super.dispose();
  }

  // ─── Clear active session ────────────────────────────────────────────────────
  void clearSession() {
    _messages.clear();
    _sessionProgress = null;
    _chatError = null;
    _isSending = false;
    _isStarting = false;
    notifyListeners();
  }
}
