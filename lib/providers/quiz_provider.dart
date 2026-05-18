import 'package:flutter/foundation.dart';
import 'package:reelscholar/models/quiz_models.dart';
import '../core/services/quiz_service.dart';

enum QuizState { idle, loading, active, submitting, done, error }

class QuizProvider extends ChangeNotifier {
  final QuizService _service = QuizService();

  QuizState _state = QuizState.idle;
  Quiz? _quiz;
  QuizResult? _result;
  String? _error;

  final Map<String, int> _answers = {};
  int _currentIndex = 0;
  DateTime? _startTime;

  QuizState get state => _state;
  Quiz? get quiz => _quiz;
  QuizResult? get result => _result;
  String? get error => _error;
  int get currentIndex => _currentIndex;
  Map<String, int> get answers => Map.unmodifiable(_answers);
  bool get isLastQuestion =>
      _quiz != null && _currentIndex >= _quiz!.questions.length - 1;

  QuizQuestion? get currentQuestion {
    if (_quiz == null || _currentIndex >= _quiz!.questions.length) return null;
    return _quiz!.questions[_currentIndex];
  }

  int? selectedAnswerForCurrent() => currentQuestion != null
      ? _answers[currentQuestion!.id]
      : null;

  List<QuizAttempt> _attempts = [];
  bool _attemptsLoading = false;
  String? _attemptsError;

  List<QuizAttempt> get attempts => _attempts;
  bool get attemptsLoading => _attemptsLoading;
  String? get attemptsError => _attemptsError;

  QuizSuggestion? _suggestion;
  bool _suggestionLoading = false;
  String? _suggestionError;

  QuizSuggestion? get suggestion => _suggestion;
  bool get suggestionLoading => _suggestionLoading;
  String? get suggestionError => _suggestionError;

  Future<void> loadQuiz(String quizId) async {
    _state = QuizState.loading;
    _error = null;
    _answers.clear();
    _currentIndex = 0;
    _result = null;
    notifyListeners();
    try {
      _quiz = await _service.getQuiz(quizId);
      _state = QuizState.active;
      _startTime = DateTime.now();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _state = QuizState.error;
    }
    notifyListeners();
  }

  void selectAnswer(String questionId, int index) {
    _answers[questionId] = index;
    notifyListeners();
  }

  void nextQuestion() {
    if (_quiz == null) return;
    if (_currentIndex < _quiz!.questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void goToQuestion(int index) {
    if (_quiz == null) return;
    if (index >= 0 && index < _quiz!.questions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<void> submitQuiz() async {
    if (_quiz == null) return;
    _state = QuizState.submitting;
    notifyListeners();

    final durationSecs = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : null;

    final answerPayload = _quiz!.questions.map((q) {
      final sel = _answers[q.id];
      return {
        'question_id': q.id,
        'selected_index': sel ?? 0,
      };
    }).toList();

    try {
      _result = await _service.submitQuiz(
        quizId: _quiz!.id,
        answers: answerPayload,
        durationSeconds: durationSecs,
      );
      _state = QuizState.done;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _state = QuizState.error;
    }
    notifyListeners();
  }

  void resetQuiz() {
    _state = QuizState.idle;
    _quiz = null;
    _result = null;
    _error = null;
    _answers.clear();
    _currentIndex = 0;
    _startTime = null;
    notifyListeners();
  }

  Future<void> loadAttempts(String moduleId) async {
    _attemptsLoading = true;
    _attemptsError = null;
    notifyListeners();
    try {
      _attempts = await _service.getAttempts(moduleId);
    } catch (e) {
      _attemptsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _attemptsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSuggestion(String moduleId) async {
    _suggestionLoading = true;
    _suggestionError = null;
    _suggestion = null;
    notifyListeners();
    try {
      _suggestion = await _service.getCurrentQuiz(moduleId);
    } catch (e) {
      _suggestionError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _suggestionLoading = false;
      notifyListeners();
    }
  }

  Future<Quiz?> generateQuiz(String moduleId) async {
    _suggestionLoading = true;
    _suggestionError = null;
    notifyListeners();
    try {
      final quiz = await _service.generateQuiz(moduleId);
      _suggestionLoading = false;
      notifyListeners();
      return quiz;
    } catch (e) {
      _suggestionError = e.toString().replaceFirst('Exception: ', '');
      _suggestionLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ── Tutor quiz (prefixed to avoid clashing with existing quiz flow) ──

  Quiz? _tutorQuiz;
  int _tutorCurrentIndex = 0;
  final Map<String, int> _tutorAnswers = {};
  final Set<String> _tutorRevealed = {};
  TutorQuizAttempt? _tutorResult;
  bool _tutorSubmitting = false;
  bool _tutorLoading = false;
  String? _tutorError;
  DateTime? _tutorStartedAt;

  Quiz? get tutorQuiz => _tutorQuiz;
  int get tutorCurrentIndex => _tutorCurrentIndex;
  Map<String, int> get tutorAnswers => Map.unmodifiable(_tutorAnswers);
  Set<String> get tutorRevealed => Set.unmodifiable(_tutorRevealed);
  TutorQuizAttempt? get attemptResult => _tutorResult;
  bool get tutorSubmitting => _tutorSubmitting;
  bool get tutorLoading => _tutorLoading;
  String? get tutorError => _tutorError;

  QuizQuestion? get tutorCurrentQuestion {
    if (_tutorQuiz == null || _tutorCurrentIndex >= _tutorQuiz!.questions.length) {
      return null;
    }
    return _tutorQuiz!.questions[_tutorCurrentIndex];
  }

  bool get tutorIsLastQuestion =>
      _tutorQuiz != null &&
      _tutorCurrentIndex >= _tutorQuiz!.questions.length - 1;

  int get tutorElapsedSeconds => _tutorStartedAt == null
      ? 0
      : DateTime.now().difference(_tutorStartedAt!).inSeconds;

  Future<void> startTutorQuiz(String quizId) async {
    _tutorLoading = true;
    _tutorError = null;
    _tutorQuiz = null;
    _tutorCurrentIndex = 0;
    _tutorAnswers.clear();
    _tutorRevealed.clear();
    _tutorResult = null;
    _tutorStartedAt = null;
    notifyListeners();
    try {
      _tutorQuiz = await _service.getTutorQuiz(quizId);
      _tutorStartedAt = DateTime.now();
    } catch (e) {
      _tutorError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _tutorLoading = false;
      notifyListeners();
    }
  }

  void tutorSelect(String questionId, int index) {
    if (_tutorRevealed.contains(questionId)) return;
    _tutorAnswers[questionId] = index;
    notifyListeners();
  }

  void tutorConfirm() {
    final q = tutorCurrentQuestion;
    if (q == null) return;
    _tutorRevealed.add(q.id);
    notifyListeners();
  }

  void tutorNext() {
    if (_tutorQuiz == null) return;
    if (_tutorCurrentIndex < _tutorQuiz!.questions.length - 1) {
      _tutorCurrentIndex++;
      notifyListeners();
    }
  }

  Future<void> tutorSubmit() async {
    if (_tutorQuiz == null) return;
    _tutorSubmitting = true;
    notifyListeners();

    final answerPayload = _tutorQuiz!.questions.map((q) => {
      'question_id': q.id,
      'selected_index': _tutorAnswers[q.id] ?? 0,
    }).toList();

    try {
      _tutorResult = await _service.submitTutorQuiz(
        quizId: _tutorQuiz!.id,
        answers: answerPayload,
        timeTakenSeconds: tutorElapsedSeconds,
      );
    } catch (e) {
      _tutorError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _tutorSubmitting = false;
      notifyListeners();
    }
  }

  void resetTutorQuiz() {
    _tutorQuiz = null;
    _tutorCurrentIndex = 0;
    _tutorAnswers.clear();
    _tutorRevealed.clear();
    _tutorResult = null;
    _tutorSubmitting = false;
    _tutorLoading = false;
    _tutorError = null;
    _tutorStartedAt = null;
    notifyListeners();
  }
}
