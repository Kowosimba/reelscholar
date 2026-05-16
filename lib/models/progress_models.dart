// lib/models/progress_models.dart

int _parseInt(dynamic v) =>
    v == null ? 0 : int.tryParse(v.toString()) ?? 0;
double _parseDouble(dynamic v) =>
    v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

// ── Overview ──────────────────────────────────────────────────────────────────

class ProgressOverview {
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int modulesTotal;
  final int modulesCompleted;
  final int modulesInProgress;
  final int totalStudyMinutes;
  final double avgQuizScore;
  final int totalQuizzes;

  const ProgressOverview({
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.modulesTotal,
    required this.modulesCompleted,
    required this.modulesInProgress,
    required this.totalStudyMinutes,
    required this.avgQuizScore,
    required this.totalQuizzes,
  });

  factory ProgressOverview.fromJson(Map<String, dynamic> j) => ProgressOverview(
        totalXp: _parseInt(j['total_xp']),
        currentStreak: _parseInt(j['current_streak']),
        longestStreak: _parseInt(j['longest_streak']),
        modulesTotal: _parseInt(j['modules_total']),
        modulesCompleted: _parseInt(j['modules_completed']),
        modulesInProgress: _parseInt(j['modules_in_progress']),
        totalStudyMinutes: _parseInt(j['total_study_minutes']),
        avgQuizScore: _parseDouble(j['avg_quiz_score']),
        totalQuizzes: _parseInt(j['total_quizzes']),
      );

  static const empty = ProgressOverview(
    totalXp: 0,
    currentStreak: 0,
    longestStreak: 0,
    modulesTotal: 0,
    modulesCompleted: 0,
    modulesInProgress: 0,
    totalStudyMinutes: 0,
    avgQuizScore: 0,
    totalQuizzes: 0,
  );
}

// ── Heatmap day ───────────────────────────────────────────────────────────────

class HeatmapDay {
  final DateTime date;
  final int minutesStudied;
  final int topicsCovered;
  final int quizzesTaken;
  final int intensity; // 0-4

  const HeatmapDay({
    required this.date,
    required this.minutesStudied,
    required this.topicsCovered,
    required this.quizzesTaken,
    required this.intensity,
  });

  factory HeatmapDay.fromJson(Map<String, dynamic> j) => HeatmapDay(
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        minutesStudied: _parseInt(j['minutes_studied']),
        topicsCovered: _parseInt(j['topics_covered']),
        quizzesTaken: _parseInt(j['quizzes_taken']),
        intensity: _parseInt(j['intensity']),
      );
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

class ProgressDashboard {
  final ProgressOverview overview;
  final List<HeatmapDay> heatmap;

  const ProgressDashboard({required this.overview, required this.heatmap});

  factory ProgressDashboard.fromJson(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>? ?? {};
    final rawOverview = data['overview'] as Map<String, dynamic>? ?? {};
    final rawHeatmap = data['activity_heatmap'] as List? ?? [];
    return ProgressDashboard(
      overview: ProgressOverview.fromJson(rawOverview),
      heatmap: rawHeatmap
          .map((d) => HeatmapDay.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Leaderboard ───────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final String rank;
  final String uid;
  final String name;
  final String? profilePic;
  final String? degreeProgramme;
  final double score;
  final int totalXp;
  final int currentStreak;

  const LeaderboardEntry({
    required this.rank,
    required this.uid,
    required this.name,
    this.profilePic,
    this.degreeProgramme,
    required this.score,
    required this.totalXp,
    required this.currentStreak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: j['rank']?.toString() ?? '',
        uid: j['uid']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        profilePic: j['profile_pic'] as String?,
        degreeProgramme: j['degree_programme'] as String?,
        score: _parseDouble(j['score']),
        totalXp: _parseInt(j['total_xp']),
        currentStreak: _parseInt(j['current_streak']),
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class LeaderboardData {
  final String scope;
  final String scopeLabel;
  final String myRank;
  final List<LeaderboardEntry> entries;

  const LeaderboardData({
    required this.scope,
    required this.scopeLabel,
    required this.myRank,
    required this.entries,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>? ?? {};
    return LeaderboardData(
      scope: data['scope']?.toString() ?? 'programme',
      scopeLabel: data['scope_label']?.toString() ?? 'Programme',
      myRank: data['my_rank']?.toString() ?? '—',
      entries: (data['entries'] as List? ?? [])
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Achievement ───────────────────────────────────────────────────────────────

class Achievement {
  final String id;
  final String hackathonId;
  final String hackathonTitle;
  final String theme;
  final String badge;
  final String badgeLabel;
  final String badgeIcon;
  final String teamName;
  final DateTime? awardedAt;

  const Achievement({
    required this.id,
    required this.hackathonId,
    required this.hackathonTitle,
    required this.theme,
    required this.badge,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.teamName,
    this.awardedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
        id: j['id']?.toString() ?? '',
        hackathonId: j['hackathon_id']?.toString() ?? '',
        hackathonTitle: j['hackathon_title']?.toString() ?? '',
        theme: j['theme']?.toString() ?? '',
        badge: j['badge']?.toString() ?? '',
        badgeLabel: j['badge_label']?.toString() ?? '',
        badgeIcon: j['badge_icon']?.toString() ?? '🏅',
        teamName: j['team_name']?.toString() ?? '',
        awardedAt: DateTime.tryParse(j['awarded_at']?.toString() ?? ''),
      );
}

// ── XP Entry ──────────────────────────────────────────────────────────────────

class XpEntry {
  final String id;
  final int amount;
  final String type;
  final String description;
  final DateTime earnedAt;

  const XpEntry({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.earnedAt,
  });

  factory XpEntry.fromJson(Map<String, dynamic> j) => XpEntry(
        id: j['id']?.toString() ?? '',
        amount: _parseInt(j['amount'] ?? j['xp'] ?? j['points']),
        type: j['type']?.toString() ?? '',
        description: j['description']?.toString() ??
            j['reason']?.toString() ??
            j['activity']?.toString() ??
            '',
        earnedAt: DateTime.tryParse(
                j['earned_at']?.toString() ??
                    j['created_at']?.toString() ??
                    '') ??
            DateTime.now(),
      );
}

// ── Module progress detail ─────────────────────────────────────────────────────

class ModuleTopicProgress {
  final String id;
  final int order;
  final String title;
  final bool isCompleted;

  const ModuleTopicProgress({
    required this.id,
    required this.order,
    required this.title,
    required this.isCompleted,
  });

  factory ModuleTopicProgress.fromJson(Map<String, dynamic> j) =>
      ModuleTopicProgress(
        id: j['id']?.toString() ?? '',
        order: _parseInt(j['order']),
        title: j['title']?.toString() ?? '',
        isCompleted: j['is_completed'] == true ||
            j['is_completed'] == 'true' ||
            j['is_completed'] == 1,
      );
}

class ModuleProgressDetail {
  final String moduleId;
  final String moduleCode;
  final String moduleName;
  final String status;
  final double progressPercentage;
  final int topicsCompleted;
  final int totalTopics;
  final int quizzesTaken;
  final double averageQuizScore;
  final double bestQuizScore;
  final int totalStudyMinutes;
  final List<ModuleTopicProgress> topics;

  const ModuleProgressDetail({
    required this.moduleId,
    required this.moduleCode,
    required this.moduleName,
    required this.status,
    required this.progressPercentage,
    required this.topicsCompleted,
    required this.totalTopics,
    required this.quizzesTaken,
    required this.averageQuizScore,
    required this.bestQuizScore,
    required this.totalStudyMinutes,
    required this.topics,
  });

  factory ModuleProgressDetail.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] ?? j) as Map<String, dynamic>;
    return ModuleProgressDetail(
      moduleId: data['module_id']?.toString() ?? '',
      moduleCode: data['module_code']?.toString() ?? '',
      moduleName: data['module_name']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      progressPercentage: _parseDouble(data['progress_percentage']),
      topicsCompleted: _parseInt(data['topics_completed']),
      totalTopics: _parseInt(data['total_topics']),
      quizzesTaken: _parseInt(data['quizzes_taken']),
      averageQuizScore: _parseDouble(data['average_quiz_score']),
      bestQuizScore: _parseDouble(data['best_quiz_score']),
      totalStudyMinutes: _parseInt(data['total_study_minutes']),
      topics: (data['topics'] as List? ?? [])
          .map((t) =>
              ModuleTopicProgress.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Topic ─────────────────────────────────────────────────────────────────────

class AppTopic {
  final String id;
  final String name;

  const AppTopic({required this.id, required this.name});

  factory AppTopic.fromJson(dynamic j) {
    if (j is String) return AppTopic(id: j, name: j);
    if (j is Map<String, dynamic>) {
      return AppTopic(
        id: j['id']?.toString() ?? j['slug']?.toString() ?? j['name']?.toString() ?? '',
        name: j['name']?.toString() ?? j['title']?.toString() ?? j['id']?.toString() ?? '',
      );
    }
    return AppTopic(id: j.toString(), name: j.toString());
  }
}
