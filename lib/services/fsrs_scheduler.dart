import 'dart:math' as math;

/// FSRS (Free Spaced Repetition Scheduler) v4.5 — Dart implementation.
///
/// Rating scale (Anki-style):
///   1 = Again (forgot)
///   2 = Hard  (recalled with serious effort)
///   3 = Good  (recalled correctly)
///   4 = Easy  (recalled effortlessly)

enum FsrsRating { again, hard, good, easy }

extension FsrsRatingValue on FsrsRating {
  int get value => switch (this) {
        FsrsRating.again => 1,
        FsrsRating.hard => 2,
        FsrsRating.good => 3,
        FsrsRating.easy => 4,
      };

  String get label => switch (this) {
        FsrsRating.again => 'Again',
        FsrsRating.hard => 'Hard',
        FsrsRating.good => 'Good',
        FsrsRating.easy => 'Easy',
      };
}

enum FsrsState { newCard, learning, review, relearning }

extension FsrsStateName on FsrsState {
  String get apiName => switch (this) {
        FsrsState.newCard => 'new',
        FsrsState.learning => 'learning',
        FsrsState.review => 'review',
        FsrsState.relearning => 'relearning',
      };

  static FsrsState fromName(String n) => switch (n) {
        'learning' => FsrsState.learning,
        'review' => FsrsState.review,
        'relearning' => FsrsState.relearning,
        _ => FsrsState.newCard,
      };
}

class FsrsCard {
  double stability;
  double difficulty;
  FsrsState state;
  DateTime due;
  DateTime? lastReview;
  int reps;
  int lapses;

  FsrsCard({
    this.stability = 0,
    this.difficulty = 0,
    this.state = FsrsState.newCard,
    DateTime? due,
    this.lastReview,
    this.reps = 0,
    this.lapses = 0,
  }) : due = due ?? DateTime.now();
}

class FsrsScheduler {
  static const List<double> w = [
    0.4072, 1.1829, 3.1262, 15.4722, 7.2102, 0.5316, 1.0651, 0.0234,
    1.616, 0.1544, 1.0824, 1.9813, 0.0953, 0.2975, 2.2042, 0.2407,
    2.9466, 0.5034, 0.6567,
  ];

  final double requestRetention;
  final int maximumInterval;

  FsrsScheduler({this.requestRetention = 0.9, this.maximumInterval = 36500});

  FsrsCard review(FsrsCard card, FsrsRating rating, [DateTime? now]) {
    final reviewTime = now ?? DateTime.now();
    final updated = FsrsCard(
      stability: card.stability,
      difficulty: card.difficulty,
      state: card.state,
      due: card.due,
      lastReview: card.lastReview,
      reps: card.reps + 1,
      lapses: card.lapses,
    );

    if (card.state == FsrsState.newCard) {
      _initState(updated, rating);
    } else {
      final elapsedDays = card.lastReview == null
          ? 0.0
          : reviewTime.difference(card.lastReview!).inSeconds / 86400.0;
      final retrievability = _retrievability(elapsedDays, card.stability);
      _nextState(updated, card, rating, retrievability, elapsedDays);
    }

    final intervalDays = _nextInterval(updated.stability);
    updated.due = reviewTime.add(Duration(
      seconds: (intervalDays * 86400).round(),
    ));
    updated.lastReview = reviewTime;
    return updated;
  }

  void _initState(FsrsCard card, FsrsRating rating) {
    final r = rating.value;
    card.difficulty = _clampDifficulty(w[4] - (r - 3) * w[5]);
    card.stability = math.max(w[r - 1], 0.1);
    card.state = (rating == FsrsRating.again)
        ? FsrsState.learning
        : FsrsState.review;
  }

  void _nextState(
    FsrsCard updated,
    FsrsCard prev,
    FsrsRating rating,
    double retrievability,
    double elapsedDays,
  ) {
    final r = rating.value;

    updated.difficulty = _clampDifficulty(prev.difficulty - w[6] * (r - 3));
    updated.difficulty = _clampDifficulty(
      w[7] * (w[4] - updated.difficulty) +
          (1 - w[7]) * updated.difficulty,
    );

    if (rating == FsrsRating.again) {
      updated.lapses = prev.lapses + 1;
      final newStability = w[11] *
          math.pow(prev.difficulty, -w[12]) *
          (math.pow(prev.stability + 1, w[13]) - 1) *
          math.exp((1 - retrievability) * w[14]);
      updated.stability = math.max(0.1, newStability.toDouble());
      updated.state = FsrsState.relearning;
    } else {
      final hardPenalty = rating == FsrsRating.hard ? w[15] : 1.0;
      final easyBonus = rating == FsrsRating.easy ? w[16] : 1.0;
      final factor = math.exp(w[8]) *
          (11 - prev.difficulty) *
          math.pow(prev.stability, -w[9]) *
          (math.exp((1 - retrievability) * w[10]) - 1) *
          hardPenalty *
          easyBonus;
      updated.stability = prev.stability * (1 + factor);
      updated.state = FsrsState.review;
    }
  }

  double _retrievability(double elapsedDays, double stability) {
    if (stability <= 0) return 0;
    return math.pow(1 + elapsedDays / (9 * stability), -1).toDouble();
  }

  double _nextInterval(double stability) {
    final ivl = 9 * stability * (1 / requestRetention - 1);
    return math.min(math.max(ivl, 1), maximumInterval.toDouble());
  }

  double _clampDifficulty(double d) => math.min(math.max(d, 1.0), 10.0);
}
