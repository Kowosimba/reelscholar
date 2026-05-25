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
    isResumed: j['is_resumed'] == true ||
        j['is_resumed']?.toString() == 'true',
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
    usedTurns: int.tryParse(j['used_turns']?.toString() ?? '') ?? 0,
    capTurns: int.tryParse(j['cap_turns']?.toString() ?? '') ?? 0,
    remainingTurns:
        int.tryParse(j['remaining_turns']?.toString() ?? '') ?? 0,
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
    turnCount: int.tryParse(j['turn_count']?.toString() ?? '') ?? 0,
    topicAdvanced: j['topic_advanced'] == true ||
        j['topic_advanced']?.toString() == 'true',
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
    currentTopicIndex:
        int.tryParse(j['current_topic_index']?.toString() ?? '') ?? 0,
    currentTopicTitle: j['current_topic_title']?.toString() ?? '',
    topicsCompleted:
        int.tryParse(j['topics_completed']?.toString() ?? '') ?? 0,
    totalTopics:
        int.tryParse(j['total_topics']?.toString() ?? '') ?? 0,
    progressPercentage:
        double.tryParse(j['progress_percentage']?.toString() ?? '') ?? 0.0,
    shouldSuggestQuiz: j['should_suggest_quiz'] == true ||
        j['should_suggest_quiz']?.toString() == 'true',
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
