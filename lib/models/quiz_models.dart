import 'dart:convert';

enum BloomLevel { remember, understand, apply, analyze }

extension BloomLevelMeta on BloomLevel {
  String get label => switch (this) {
    BloomLevel.remember => 'Remember',
    BloomLevel.understand => 'Understand',
    BloomLevel.apply => 'Apply',
    BloomLevel.analyze => 'Analyze',
  };

  static BloomLevel? fromString(String? s) => switch (s) {
    'remember' => BloomLevel.remember,
    'understand' => BloomLevel.understand,
    'apply' => BloomLevel.apply,
    'analyze' => BloomLevel.analyze,
    _ => null,
  };
}

enum QuizDifficulty { easy, medium, hard }

extension QuizDifficultyMeta on QuizDifficulty {
  String get label => switch (this) {
    QuizDifficulty.easy => 'Easy',
    QuizDifficulty.medium => 'Medium',
    QuizDifficulty.hard => 'Hard',
  };

  static QuizDifficulty? fromString(String? s) => switch (s) {
    'easy' => QuizDifficulty.easy,
    'medium' => QuizDifficulty.medium,
    'hard' => QuizDifficulty.hard,
    _ => null,
  };
}

class QuizQuestion {
  final String id;
  final int order;
  final String question;
  final List<String> options;
  final String? explanation;
  final int? correctIndex;
  final BloomLevel? bloomLevel;
  final QuizDifficulty? quizDifficulty;
  final String? topicTitle;
  final int? topicIndex;

  const QuizQuestion({
    required this.id,
    required this.order,
    required this.question,
    required this.options,
    this.explanation,
    this.correctIndex,
    this.bloomLevel,
    this.quizDifficulty,
    this.topicTitle,
    this.topicIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<String> opts = [];
    if (rawOptions is List) {
      opts = rawOptions.map((e) => e.toString()).toList();
    } else if (rawOptions is String && rawOptions.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawOptions) as List<dynamic>?;
        opts = decoded?.map((e) => e.toString()).toList() ?? [];
      } catch (_) {
        opts = [];
      }
    }
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      order: int.tryParse(json['order'].toString()) ?? 0,
      question: json['question']?.toString() ?? '',
      options: opts,
      explanation: json['explanation']?.toString(),
      correctIndex: json['correct_index'] != null
          ? int.tryParse(json['correct_index'].toString())
          : null,
      bloomLevel: BloomLevelMeta.fromString(json['bloom_level']?.toString()),
      quizDifficulty: QuizDifficultyMeta.fromString(json['difficulty']?.toString()),
      topicTitle: json['topic_title']?.toString(),
      topicIndex: json['topic_index'] != null
          ? int.tryParse(json['topic_index'].toString())
          : null,
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final String type;
  final int questionCount;
  final List<String>? topicsCovered;
  final String? moduleId;
  final List<QuizQuestion> questions;
  final DateTime? createdAt;

  const Quiz({
    required this.id,
    required this.title,
    required this.type,
    required this.questionCount,
    this.topicsCovered,
    this.moduleId,
    required this.questions,
    this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['topics_covered'];
    List<String>? topics;
    if (rawTopics is List) {
      topics = rawTopics.map((e) => e.toString()).toList();
    } else if (rawTopics is String && rawTopics.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTopics);
        if (decoded is List) {
          topics = decoded.map((e) => e.toString()).toList();
        } else {
          topics = [rawTopics];
        }
      } catch (_) {
        topics = [rawTopics];
      }
    }

    String? modId;
    final mod = json['module'];
    if (mod is Map<String, dynamic>) {
      modId = mod['id']?.toString();
    } else if (mod is String) {
      modId = mod;
    }

    return Quiz(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Quiz',
      type: json['type']?.toString() ?? 'mcq',
      questionCount: int.tryParse(json['question_count'].toString()) ?? 0,
      topicsCovered: topics,
      moduleId: modId,
      questions: (json['questions'] as List? ?? [])
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class QuizResultItem {
  final String questionId;
  final String question;
  final int correctIndex;
  final String? explanation;
  final String? yourAnswer;
  final bool isCorrect;

  const QuizResultItem({
    required this.questionId,
    required this.question,
    required this.correctIndex,
    this.explanation,
    this.yourAnswer,
    required this.isCorrect,
  });

  factory QuizResultItem.fromJson(Map<String, dynamic> json) {
    final rawCorrect = json['is_correct'];
    var correct = false;
    if (rawCorrect is bool) {
      correct = rawCorrect;
    } else if (rawCorrect is String) {
      correct = rawCorrect == 'true' || rawCorrect == '1';
    }
    return QuizResultItem(
      questionId: json['question_id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      correctIndex: int.tryParse(json['correct_index'].toString()) ?? 0,
      explanation: json['explanation']?.toString(),
      yourAnswer: json['your_answer']?.toString(),
      isCorrect: correct,
    );
  }
}

class QuizResult {
  final String attemptId;
  final int score;
  final int total;
  final double percentage;
  final List<QuizResultItem> results;

  const QuizResult({
    required this.attemptId,
    required this.score,
    required this.total,
    required this.percentage,
    required this.results,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      attemptId: json['attempt_id']?.toString() ?? '',
      score: int.tryParse(json['score'].toString()) ?? 0,
      total: int.tryParse(json['total'].toString()) ?? 0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
      results: (json['results'] as List? ?? [])
          .map((r) => QuizResultItem.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  String get grade {
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 60) return 'Good effort';
    if (percentage >= 40) return 'Keep going';
    return 'Needs review';
  }

  String get gradeEmoji {
    if (percentage >= 80) return '🏆';
    if (percentage >= 60) return '🎯';
    if (percentage >= 40) return '💪';
    return '📚';
  }
}

class QuizAttempt {
  final String attemptId;
  final String quizId;
  final String quizTitle;
  final int score;
  final int total;
  final double percentage;
  final int? durationSeconds;
  final DateTime createdAt;

  const QuizAttempt({
    required this.attemptId,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.total,
    required this.percentage,
    this.durationSeconds,
    required this.createdAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      attemptId: json['id']?.toString() ?? json['attempt_id']?.toString() ?? '',
      quizId: json['quiz_id']?.toString() ??
          (json['quiz'] as Map<String, dynamic>?)?['id']?.toString() ??
          '',
      quizTitle: json['quiz_title']?.toString() ??
          (json['quiz'] as Map<String, dynamic>?)?['title']?.toString() ??
          'Quiz',
      score: int.tryParse(json['score'].toString()) ?? 0,
      total: int.tryParse(json['total'].toString()) ?? 0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
      durationSeconds: json['duration_seconds'] != null
          ? int.tryParse(json['duration_seconds'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ??
          DateTime.now(),
    );
  }
}

class QuizSuggestion {
  final String quizId;
  final String title;
  final String questions;

  const QuizSuggestion({
    required this.quizId,
    required this.title,
    required this.questions,
  });

  factory QuizSuggestion.fromJson(Map<String, dynamic> json) {
    final rawQ = json['questions'];
    String questionsStr;
    if (rawQ is List) {
      questionsStr = rawQ.length.toString();
    } else if (rawQ is int) {
      questionsStr = rawQ.toString();
    } else {
      // Fall back to question_count (used by the Quiz model) or zero
      final rawCount = json['question_count'];
      questionsStr = rawCount?.toString() ?? rawQ?.toString() ?? '0';
    }
    return QuizSuggestion(
      quizId: json['quiz_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Quiz',
      questions: questionsStr,
    );
  }
}

class TutorQuizAttempt {
  final String id;
  final int score;
  final int total;
  final double percentage;
  final int timeTakenSeconds;
  final Map<String, Map<String, dynamic>> breakdown;

  const TutorQuizAttempt({
    required this.id,
    required this.score,
    required this.total,
    required this.percentage,
    required this.timeTakenSeconds,
    required this.breakdown,
  });

  factory TutorQuizAttempt.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'];
    final Map<String, Map<String, dynamic>> bd = {};
    if (rawBreakdown is Map) {
      rawBreakdown.forEach((k, v) {
        if (v is Map) {
          bd[k.toString()] = Map<String, dynamic>.from(v);
        }
      });
    }
    return TutorQuizAttempt(
      id: json['id']?.toString() ?? '',
      score: int.tryParse(json['score'].toString()) ?? 0,
      total: int.tryParse(json['total'].toString()) ?? 0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
      timeTakenSeconds: int.tryParse(json['time_taken_seconds'].toString()) ?? 0,
      breakdown: bd,
    );
  }

  Map<String, ({int correct, int total})> bucket(String key) {
    final section = breakdown[key];
    if (section == null) return {};
    final result = <String, ({int correct, int total})>{};
    section.forEach((label, v) {
      if (v is Map) {
        final correct = int.tryParse(v['correct'].toString()) ?? 0;
        final tot = int.tryParse(v['total'].toString()) ?? 0;
        result[label] = (correct: correct, total: tot);
      }
    });
    return result;
  }
}
