import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// Module
// ─────────────────────────────────────────────────────────────────────────────

class TutorModule {
  final String moduleId;
  final String code;
  final String name;
  final String credits;
  final int yearLevel;
  final int semester;
  final String status; // not_started | in_progress | completed
  final double progressPercentage;
  final int topicsCompleted;
  final int totalTopics;
  final int quizzesTaken;
  final double averageQuizScore;
  final bool isCurrent;

  const TutorModule({
    required this.moduleId,
    required this.code,
    required this.name,
    required this.credits,
    required this.yearLevel,
    required this.semester,
    required this.status,
    required this.progressPercentage,
    required this.topicsCompleted,
    required this.totalTopics,
    required this.quizzesTaken,
    required this.averageQuizScore,
    required this.isCurrent,
  });

  factory TutorModule.fromJson(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return TutorModule(
      moduleId: j['module_id']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      credits: j['credits']?.toString() ?? '',
      yearLevel: toInt(j['year_level']),
      semester: toInt(j['semester']),
      status: j['status']?.toString() ?? 'not_started',
      progressPercentage: toDouble(j['progress_percentage']),
      topicsCompleted: toInt(j['topics_completed']),
      totalTopics: toInt(j['total_topics']),
      quizzesTaken: toInt(j['quizzes_taken']),
      averageQuizScore: toDouble(j['average_quiz_score']),
      isCurrent:
          j['is_current']?.toString() == 'true' ||
          j['is_current'] == true ||
          j['is_current'] == 1,
    );
  }

  bool get isNotStarted => status == 'not_started';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
}

// ─────────────────────────────────────────────────────────────────────────────
// Session Progress
// ─────────────────────────────────────────────────────────────────────────────

class SessionProgress {
  final String status;
  final int currentTopicIndex;
  final int topicsCompleted;
  final int totalTopics;
  final double progressPercentage;
  final bool shouldSuggestQuiz;

  const SessionProgress({
    required this.status,
    required this.currentTopicIndex,
    required this.topicsCompleted,
    required this.totalTopics,
    required this.progressPercentage,
    required this.shouldSuggestQuiz,
  });

  factory SessionProgress.fromJson(Map<String, dynamic> j) => SessionProgress(
    status: j['status']?.toString() ?? '',
    currentTopicIndex: j['current_topic_index'] as int? ?? 0,
    topicsCompleted: j['topics_completed'] as int? ?? 0,
    totalTopics: j['total_topics'] as int? ?? 0,
    progressPercentage:
        double.tryParse(j['progress_percentage']?.toString() ?? '0') ?? 0,
    shouldSuggestQuiz: j['should_suggest_quiz'] as bool? ?? false,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Session Start Result
// ─────────────────────────────────────────────────────────────────────────────

class SessionStartResult {
  final String message;
  final String? conversationId;
  final SessionProgress progress;

  const SessionStartResult({
    required this.message,
    this.conversationId,
    required this.progress,
  });

  factory SessionStartResult.fromJson(Map<String, dynamic> j) =>
      SessionStartResult(
        message: j['message']?.toString() ?? '',
        conversationId: j['conversation_id']?.toString(),
        progress: SessionProgress.fromJson(
          j['progress'] as Map<String, dynamic>,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Message
// ─────────────────────────────────────────────────────────────────────────────

enum MessageRole { user, tutor }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final SessionProgress? progress; // only on tutor replies

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.progress,
  });

  factory ChatMessage.user(String content) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    role: MessageRole.user,
    content: content,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.tutor(String content, {SessionProgress? progress}) =>
      ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_t',
        role: MessageRole.tutor,
        content: content,
        timestamp: DateTime.now(),
        progress: progress,
      );

  /// Build from raw history item — API returns history as mixed JSON/string
  factory ChatMessage.fromHistoryJson(Map<String, dynamic> j) {
    final role = j['role']?.toString() == 'user'
        ? MessageRole.user
        : MessageRole.tutor;
    return ChatMessage(
      id:
          j['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      role: role,
      content: j['content']?.toString() ?? j['message']?.toString() ?? '',
      timestamp:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isTutor => role == MessageRole.tutor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Flashcard
// ─────────────────────────────────────────────────────────────────────────────

class Flashcard {
  final String id;
  final String front; // concept / question
  final String back; // answer / definition
  FlashcardStatus status;

  Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.status = FlashcardStatus.unseen,
  });

  /// API returns cards as strings — attempt JSON parse, else use as-is
  factory Flashcard.fromRaw(String raw, int index) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Flashcard(
        id: json['id']?.toString() ?? '$index',
        front:
            json['front']?.toString() ??
            json['concept']?.toString() ??
            json['question']?.toString() ??
            raw,
        back:
            json['back']?.toString() ??
            json['definition']?.toString() ??
            json['answer']?.toString() ??
            '',
      );
    } catch (_) {
      // Plain string — treat as front-only card
      final parts = raw.split('|');
      return Flashcard(
        id: '$index',
        front: parts.isNotEmpty ? parts[0].trim() : raw,
        back: parts.length > 1 ? parts[1].trim() : '',
      );
    }
  }
}

enum FlashcardStatus { unseen, known, learning }

// ─────────────────────────────────────────────────────────────────────────────
// Concept Map
// ─────────────────────────────────────────────────────────────────────────────

class ConceptNode {
  final String id;
  final String label;
  final String type; // module | topic | concept
  final String summary;
  final List<String> children; // edge targets

  const ConceptNode({
    required this.id,
    required this.label,
    required this.type,
    required this.summary,
    required this.children,
  });

  factory ConceptNode.fromJson(Map<String, dynamic> j) => ConceptNode(
    id: j['id']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    type: j['type']?.toString() ?? 'concept',
    summary: j['summary']?.toString() ?? '',
    children: [],
  );
}

class ConceptMap {
  final String moduleId;
  final List<ConceptNode> nodes;
  final List<String> edges; // raw edge strings "source -> target"

  const ConceptMap({
    required this.moduleId,
    required this.nodes,
    required this.edges,
  });

  factory ConceptMap.fromJson(Map<String, dynamic> j) {
    final rawNodes = j['nodes'] as List<dynamic>? ?? [];
    final rawEdges = j['edges'] as List<dynamic>? ?? [];

    final nodes = rawNodes.map((n) {
      if (n is Map<String, dynamic>) return ConceptNode.fromJson(n);
      // Sometimes nodes are strings
      return ConceptNode(
        id: n.toString(),
        label: n.toString(),
        type: 'concept',
        summary: '',
        children: [],
      );
    }).toList();

    // Build adjacency from edges
    final edgeStrs = rawEdges.map((e) => e.toString()).toList();
    for (final edge in edgeStrs) {
      final parts = edge.split('->').map((s) => s.trim()).toList();
      if (parts.length == 2) {
        final src = nodes.where((n) => n.id == parts[0]).toList();
        if (src.isNotEmpty) {
          src.first.children.add(parts[1]);
        }
      }
    }

    return ConceptMap(
      moduleId: j['module_id']?.toString() ?? '',
      nodes: nodes,
      edges: edgeStrs,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Voice Lesson
// ─────────────────────────────────────────────────────────────────────────────

class VoiceLessonSegment {
  final String type; // intro | explanation | example | summary | question
  final String title;
  final String content;
  final int? durationSeconds;

  const VoiceLessonSegment({
    required this.type,
    required this.title,
    required this.content,
    this.durationSeconds,
  });

  factory VoiceLessonSegment.fromJson(Map<String, dynamic> j) =>
      VoiceLessonSegment(
        type: j['type']?.toString() ?? 'explanation',
        title: j['title']?.toString() ?? '',
        content:
            j['content']?.toString() ??
            j['text']?.toString() ??
            j['script']?.toString() ??
            '',
        durationSeconds: j['duration_seconds'] as int?,
      );
}

class VoiceLesson {
  final String moduleId;
  final String title;
  final String focusTopic;
  final int? estimatedDurationMinutes;
  final List<VoiceLessonSegment> segments;

  const VoiceLesson({
    required this.moduleId,
    required this.title,
    required this.focusTopic,
    this.estimatedDurationMinutes,
    required this.segments,
  });

  factory VoiceLesson.fromJson(Map<String, dynamic> j) {
    final rawSegments = j['segments'];
    List<VoiceLessonSegment> segs = [];

    if (rawSegments is List) {
      segs = rawSegments.map((s) {
        if (s is Map<String, dynamic>) return VoiceLessonSegment.fromJson(s);
        return VoiceLessonSegment(
          type: 'explanation',
          title: 'Section',
          content: s.toString(),
        );
      }).toList();
    } else if (rawSegments is String) {
      // API returns segments as JSON string — parse it
      try {
        final parsed = jsonDecode(rawSegments) as List<dynamic>;
        segs = parsed
            .map((s) => VoiceLessonSegment.fromJson(s as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Plain script string — split into paragraphs
        final paragraphs = rawSegments.split('\n\n').where((p) => p.isNotEmpty);
        segs = paragraphs
            .toList()
            .asMap()
            .entries
            .map(
              (e) => VoiceLessonSegment(
                type: e.key == 0 ? 'intro' : 'explanation',
                title: 'Part ${e.key + 1}',
                content: e.value.trim(),
              ),
            )
            .toList();
      }
    }

    int? dur;
    final rawDur = j['estimated_duration_minutes'];
    if (rawDur is int) dur = rawDur;
    if (rawDur is Map && rawDur.containsKey('value')) {
      dur = rawDur['value'] as int?;
    }

    return VoiceLesson(
      moduleId: j['module_id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      focusTopic: j['focus_topic']?.toString() ?? '',
      estimatedDurationMinutes: dur,
      segments: segs,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session History Entry
// ─────────────────────────────────────────────────────────────────────────────

class SessionHistoryEntry {
  final String id;
  final DateTime date;
  final List<String> topics;
  final int messageCount;
  final double progressPercent;
  final int xpEarned;
  final bool isActive;

  const SessionHistoryEntry({
    required this.id,
    required this.date,
    required this.topics,
    required this.messageCount,
    required this.progressPercent,
    required this.xpEarned,
    required this.isActive,
  });

  factory SessionHistoryEntry.fromJson(Map<String, dynamic> j) =>
      SessionHistoryEntry(
        id: j['id']?.toString() ?? '',
        date:
            DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
        topics: (j['topics'] as List<dynamic>? ?? [])
            .map((t) => t.toString())
            .toList(),
        messageCount: j['message_count'] as int? ?? 0,
        progressPercent:
            double.tryParse(j['progress_percentage']?.toString() ?? '0') ?? 0,
        xpEarned: j['xp_earned'] as int? ?? 0,
        isActive: j['is_active'] as bool? ?? false,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tutor API aggregates (from /tutor/modules and /tutor/.../chat)
// ─────────────────────────────────────────────────────────────────────────────

class ModulesResponse {
  final List<TutorModule> currentModules;
  final List<TutorModule> relatedModules;

  const ModulesResponse({
    required this.currentModules,
    required this.relatedModules,
  });

  /// Group current modules by year, then semester.
  Map<int, Map<int, List<TutorModule>>> get grouped {
    final Map<int, Map<int, List<TutorModule>>> result = {};
    for (final m in currentModules) {
      result.putIfAbsent(m.yearLevel, () => {});
      result[m.yearLevel]!.putIfAbsent(m.semester, () => []);
      result[m.yearLevel]![m.semester]!.add(m);
    }
    return result;
  }
}

class ChatResponse {
  final String message;
  final SessionProgress progress;

  const ChatResponse({required this.message, required this.progress});
}
