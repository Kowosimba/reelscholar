class VoiceCallSession {
  final String callId;
  final String openingLine;
  final String topicTitle;
  final bool isResumed;
  final VoiceProgress progress;
  final VoiceQuota quota;

  VoiceCallSession({
    required this.callId,
    required this.openingLine,
    required this.topicTitle,
    required this.isResumed,
    required this.progress,
    required this.quota,
  });

  factory VoiceCallSession.fromJson(Map<String, dynamic> j) => VoiceCallSession(
    callId: j['call_id']?.toString() ?? '',
    openingLine: j['opening_line']?.toString() ?? '',
    topicTitle: (j['progress'] as Map<String, dynamic>?)?['current_topic_title']?.toString() ??
        j['topic_title']?.toString() ?? '',
    isResumed: j['is_resumed'] == true,
    progress: VoiceProgress.fromJson((j['progress'] as Map<String, dynamic>?) ?? {}),
    quota: VoiceQuota.fromJson((j['quota'] as Map<String, dynamic>?) ?? {}),
  );
}

class VoiceQuota {
  final int usedTurns;
  final int capTurns;
  final int remainingTurns;

  VoiceQuota({
    required this.usedTurns,
    required this.capTurns,
    required this.remainingTurns,
  });

  factory VoiceQuota.fromJson(Map<String, dynamic> j) => VoiceQuota(
    usedTurns: (j['used_turns'] as num?)?.toInt() ?? 0,
    capTurns: (j['cap_turns'] as num?)?.toInt() ?? 0,
    remainingTurns: (j['remaining_turns'] as num?)?.toInt() ?? 0,
  );
}

class VoiceTurnResult {
  final String replyText;
  final int turnCount;
  final bool topicAdvanced;
  final VoiceProgress progress;

  VoiceTurnResult({
    required this.replyText,
    required this.turnCount,
    required this.topicAdvanced,
    required this.progress,
  });

  factory VoiceTurnResult.fromJson(Map<String, dynamic> j) => VoiceTurnResult(
    replyText: j['reply_text']?.toString() ?? '',
    turnCount: (j['turn_count'] as num?)?.toInt() ?? 0,
    topicAdvanced: j['topic_advanced'] == true,
    progress: VoiceProgress.fromJson(
      (j['progress'] as Map<String, dynamic>?) ?? {},
    ),
  );
}

class VoiceProgress {
  final int currentTopicIndex;
  final String currentTopicTitle;
  final int topicsCompleted;
  final int totalTopics;
  final double progressPercentage;
  final bool shouldSuggestQuiz;

  VoiceProgress({
    required this.currentTopicIndex,
    required this.currentTopicTitle,
    required this.topicsCompleted,
    required this.totalTopics,
    required this.progressPercentage,
    required this.shouldSuggestQuiz,
  });

  factory VoiceProgress.fromJson(Map<String, dynamic> j) => VoiceProgress(
    currentTopicIndex: (j['current_topic_index'] as num?)?.toInt() ?? 0,
    currentTopicTitle: j['current_topic_title']?.toString() ?? '',
    topicsCompleted: (j['topics_completed'] as num?)?.toInt() ?? 0,
    totalTopics: (j['total_topics'] as num?)?.toInt() ?? 0,
    progressPercentage: (j['progress_percentage'] as num?)?.toDouble() ?? 0.0,
    shouldSuggestQuiz: j['should_suggest_quiz'] == true,
  );
}

class VoiceEndSummary {
  final String callId;
  final String status;
  final int durationSeconds;
  final int turnCount;

  VoiceEndSummary({
    required this.callId,
    required this.status,
    required this.durationSeconds,
    required this.turnCount,
  });

  factory VoiceEndSummary.fromJson(Map<String, dynamic> j) => VoiceEndSummary(
    callId: j['call_id']?.toString() ?? '',
    status: j['status']?.toString() ?? '',
    durationSeconds: (j['duration_seconds'] as num?)?.toInt() ?? 0,
    turnCount: (j['turn_count'] as num?)?.toInt() ?? 0,
  );
}

enum CallState {
  idle,
  connecting,
  listening,
  thinking,
  speaking,
  paused,
  ended,
  error,
}

class CallTranscriptLine {
  final String text;
  final bool isUser;
  final DateTime at;
  CallTranscriptLine({required this.text, required this.isUser, required this.at});
}

class VoiceQuotaException implements Exception {
  final String message;
  final int retryAfterSeconds;
  VoiceQuotaException(this.message, {this.retryAfterSeconds = 0});
  @override
  String toString() => message;
}

class VoiceCallEndedException implements Exception {
  const VoiceCallEndedException();
  @override
  String toString() => 'Session ended.';
}

class VoiceTutorUnavailableException implements Exception {
  const VoiceTutorUnavailableException();
  @override
  String toString() => 'Tutor had trouble, tap to retry.';
}
