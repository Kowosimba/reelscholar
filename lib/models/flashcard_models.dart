import 'fsrs_models.dart';

class FlashcardDeck {
  final String id;
  final String title;
  final int cardCount;
  final List<int> topicRange; // [from, to]
  final DateTime createdAt;
  final List<Flashcard> cards;

  FlashcardDeck({
    required this.id,
    required this.title,
    required this.cardCount,
    required this.topicRange,
    required this.createdAt,
    required this.cards,
  });

  factory FlashcardDeck.fromJson(Map<String, dynamic> j) => FlashcardDeck(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? 'Flashcards',
        cardCount: (j['card_count'] as num?)?.toInt() ?? 0,
        topicRange: (j['topic_range'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [0, 0],
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
        cards: (j['cards'] as List?)
                ?.map((c) => Flashcard.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );

  int get dueCount => cards.where((c) => c.isDue).length;
  int get newCount =>
      cards.where((c) => c.fsrsState == FsrsState.newCard).length;
}

enum FlashcardType { definition, cloze, application, comparison, example }

extension FlashcardTypeMeta on FlashcardType {
  String get label => switch (this) {
        FlashcardType.definition => 'Definition',
        FlashcardType.cloze => 'Cloze',
        FlashcardType.application => 'Application',
        FlashcardType.comparison => 'Comparison',
        FlashcardType.example => 'Example',
      };

  static FlashcardType fromString(String s) => switch (s) {
        'cloze' => FlashcardType.cloze,
        'application' => FlashcardType.application,
        'comparison' => FlashcardType.comparison,
        'example' => FlashcardType.example,
        _ => FlashcardType.definition,
      };
}

class Flashcard {
  final String id;
  final int order;
  final String front;
  final String back;
  final FlashcardType type;
  final int topicIndex;
  final String topicTitle;
  final int difficulty; // 1-3, content difficulty rating from the agent
  final String hint;
  final List<String> tags;

  // FSRS scheduling state
  final double fsrsStability;
  final double fsrsDifficulty;
  final FsrsState fsrsState;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;

  Flashcard({
    required this.id,
    required this.order,
    required this.front,
    required this.back,
    required this.type,
    required this.topicIndex,
    required this.topicTitle,
    required this.difficulty,
    required this.hint,
    required this.tags,
    required this.fsrsStability,
    required this.fsrsDifficulty,
    required this.fsrsState,
    required this.dueAt,
    required this.lastReviewedAt,
    required this.reviewCount,
  });

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        id: j['id']?.toString() ?? '',
        order: (j['order'] as num?)?.toInt() ?? 0,
        front: j['front']?.toString() ?? '',
        back: j['back']?.toString() ?? '',
        type: FlashcardTypeMeta.fromString(j['type']?.toString() ?? 'definition'),
        topicIndex: (j['topic_index'] as num?)?.toInt() ?? 0,
        topicTitle: j['topic_title']?.toString() ?? '',
        difficulty: (j['difficulty'] as num?)?.toInt() ?? 1,
        hint: j['hint']?.toString() ?? '',
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        fsrsStability: (j['srs_stability'] as num?)?.toDouble() ?? 0,
        fsrsDifficulty: (j['srs_difficulty'] as num?)?.toDouble() ?? 0,
        fsrsState: FsrsStateName.fromName(j['srs_state']?.toString() ?? 'new'),
        dueAt: DateTime.tryParse(j['due_at']?.toString() ?? '') ?? DateTime.now(),
        lastReviewedAt: j['last_reviewed_at'] == null
            ? null
            : DateTime.tryParse(j['last_reviewed_at'].toString()),
        reviewCount: (j['review_count'] as num?)?.toInt() ?? 0,
      );

  bool get isDue => dueAt.isBefore(DateTime.now()) ||
      fsrsState == FsrsState.newCard;
}
