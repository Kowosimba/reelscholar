import 'package:flutter/foundation.dart';
import '../models/flashcard_models.dart';
import '../services/flashcard_service.dart';
import '../services/fsrs_scheduler.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardService _service;
  final FsrsScheduler _scheduler;

  FlashcardProvider({FlashcardService? service, FsrsScheduler? scheduler})
      : _service = service ?? FlashcardService(),
        _scheduler = scheduler ?? FsrsScheduler();

  List<FlashcardDeck> _decks = [];
  List<FlashcardDeck> get decks => _decks;

  bool _loadingList = false;
  bool get loadingList => _loadingList;

  FlashcardDeck? _activeDeck;
  FlashcardDeck? get activeDeck => _activeDeck;

  List<Flashcard> _queue = [];
  int _index = 0;

  Flashcard? get currentCard =>
      _index < _queue.length ? _queue[_index] : null;
  int get queuePosition => _index;
  int get queueLength => _queue.length;
  int get remainingInSession => _queue.length - _index;

  bool _showBack = false;
  bool get showBack => _showBack;

  int _sessionReviewed = 0;
  int _sessionCorrect = 0;
  int get sessionReviewed => _sessionReviewed;
  int get sessionCorrect => _sessionCorrect;

  bool _generating = false;
  bool get generating => _generating;

  String? _error;
  String? get error => _error;

  Future<void> loadDecks(String moduleId) async {
    _loadingList = true;
    _error = null;
    notifyListeners();
    try {
      _decks = await _service.listDecks(moduleId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingList = false;
      notifyListeners();
    }
  }

  Future<FlashcardDeck?> generate(String moduleId, {int count = 20}) async {
    _generating = true;
    _error = null;
    notifyListeners();
    try {
      final deck = await _service.generateDeck(moduleId, count: count);
      _decks = [deck, ..._decks];
      return deck;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  Future<void> startSession(String deckId) async {
    _error = null;
    notifyListeners();
    try {
      final deck = await _service.getDeck(deckId);
      _activeDeck = deck;
      final due = deck.cards.where((c) =>
          c.fsrsState != FsrsState.newCard && c.isDue).toList();
      final newCards = deck.cards
          .where((c) => c.fsrsState == FsrsState.newCard)
          .toList();
      _queue = [...due, ...newCards];
      if (_queue.isEmpty) {
        _queue = [...deck.cards];
      }
      _index = 0;
      _showBack = false;
      _sessionReviewed = 0;
      _sessionCorrect = 0;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void flip() {
    _showBack = !_showBack;
    notifyListeners();
  }

  Future<void> rate(FsrsRating rating) async {
    final card = currentCard;
    if (card == null) return;

    final fsrsCard = FsrsCard(
      stability: card.fsrsStability,
      difficulty: card.fsrsDifficulty,
      state: card.fsrsState,
      due: card.dueAt,
      lastReview: card.lastReviewedAt,
      reps: card.reviewCount,
    );
    final updated = _scheduler.review(fsrsCard, rating);

    _service
        .reviewCard(
          cardId: card.id,
          rating: rating.value,
          stability: updated.stability,
          difficulty: updated.difficulty,
          state: updated.state.apiName,
          dueAt: updated.due,
        )
        .catchError((e) => debugPrint('Review sync failed: $e'));

    _sessionReviewed++;
    if (rating != FsrsRating.again) _sessionCorrect++;

    if (rating == FsrsRating.again && _index < _queue.length - 1) {
      final insertAt = (_index + 3).clamp(_index + 1, _queue.length);
      _queue.insert(insertAt, card);
    }

    _index++;
    _showBack = false;
    notifyListeners();
  }

  void endSession() {
    _activeDeck = null;
    _queue = [];
    _index = 0;
    _sessionReviewed = 0;
    _sessionCorrect = 0;
    _showBack = false;
    notifyListeners();
  }
}
