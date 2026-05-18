class VoiceCallSession {
  final String callId;
  final String openingLine;
  final String topicTitle;
  final VoiceQuota quota;

  VoiceCallSession({
    required this.callId,
    required this.openingLine,
    required this.topicTitle,
    required this.quota,
  });

  factory VoiceCallSession.fromJson(Map<String, dynamic> j) => VoiceCallSession(
    callId: j['call_id']?.toString() ?? '',
    openingLine: j['opening_line']?.toString() ?? '',
    topicTitle: j['topic_title']?.toString() ?? '',
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
  final VoiceProgress progress;
  final bool advanceSuggested;

  VoiceTurnResult({
    required this.replyText,
    required this.turnCount,
    required this.progress,
    required this.advanceSuggested,
  });

  factory VoiceTurnResult.fromJson(Map<String, dynamic> j) => VoiceTurnResult(
    replyText: j['reply_text']?.toString() ?? '',
    turnCount: (j['turn_count'] as num?)?.toInt() ?? 0,
    progress: VoiceProgress.fromJson(
      (j['progress'] as Map<String, dynamic>?) ?? {},
    ),
    advanceSuggested: j['advance_suggested'] == true,
  );
}

class VoiceProgress {
  final int currentTopicIndex;
  final int topicsCompleted;
  final int totalTopics;
  final double progressPercentage;

  VoiceProgress({
    required this.currentTopicIndex,
    required this.topicsCompleted,
    required this.totalTopics,
    required this.progressPercentage,
  });

  factory VoiceProgress.fromJson(Map<String, dynamic> j) => VoiceProgress(
    currentTopicIndex: (j['current_topic_index'] as num?)?.toInt() ?? 0,
    topicsCompleted: (j['topics_completed'] as num?)?.toInt() ?? 0,
    totalTopics: (j['total_topics'] as num?)?.toInt() ?? 0,
    progressPercentage: (j['progress_percentage'] as num?)?.toDouble() ?? 0.0,
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
