// lib/models/hackathon_models.dart

import 'package:flutter/material.dart';

// ── Status enum ───────────────────────────────────────────────────────────────

enum HackStatus {
  draft,
  published,
  registrationOpen,  // API: "registration_open"
  inProgress,        // API: "in_progress"
  submissionClosed,  // API: "submission_closed"
  votingOpen,        // API: "voting_open"
  judging,
  completed,         // API: "completed"
  ended,             // API: "ended" (legacy / fallback)
}

extension HackStatusX on HackStatus {
  static HackStatus from(String s) {
    switch (s.toLowerCase()) {
      case 'published':          return HackStatus.published;
      case 'registration_open':  return HackStatus.registrationOpen;
      case 'in_progress':
      case 'ongoing':            return HackStatus.inProgress;
      case 'submission_closed':
      case 'submission':         return HackStatus.submissionClosed;
      case 'voting_open':
      case 'voting':             return HackStatus.votingOpen;
      case 'judging':            return HackStatus.judging;
      case 'completed':          return HackStatus.completed;
      case 'ended':              return HackStatus.ended;
      default:                   return HackStatus.draft;
    }
  }

  String get label {
    switch (this) {
      case HackStatus.published:         return 'Published';
      case HackStatus.registrationOpen:  return 'Registration Open';
      case HackStatus.inProgress:        return 'In Progress';
      case HackStatus.submissionClosed:  return 'Submissions Closed';
      case HackStatus.votingOpen:        return 'Voting Open';
      case HackStatus.judging:           return 'Judging';
      case HackStatus.completed:         return 'Completed';
      case HackStatus.ended:             return 'Ended';
      default:                           return 'Draft';
    }
  }

  Color get color {
    switch (this) {
      case HackStatus.published:
      case HackStatus.registrationOpen:  return const Color(0xFF22C55E);
      case HackStatus.inProgress:        return const Color(0xFF3B82F6);
      case HackStatus.submissionClosed:  return const Color(0xFF6366F1);
      case HackStatus.votingOpen:        return const Color(0xFFF59E0B);
      case HackStatus.judging:           return const Color(0xFFEC4899);
      case HackStatus.completed:
      case HackStatus.ended:             return const Color(0xFF64748B);
      default:                           return const Color(0xFF94A3B8);
    }
  }

  Color get bg {
    switch (this) {
      case HackStatus.published:
      case HackStatus.registrationOpen:  return const Color(0xFFDCFCE7);
      case HackStatus.inProgress:        return const Color(0xFFDBEAFE);
      case HackStatus.submissionClosed:  return const Color(0xFFEDE9FE);
      case HackStatus.votingOpen:        return const Color(0xFFFEF3C7);
      case HackStatus.judging:           return const Color(0xFFFCE7F3);
      case HackStatus.completed:
      case HackStatus.ended:             return const Color(0xFFF1F5F9);
      default:                           return const Color(0xFFF8FAFC);
    }
  }

  bool get canRegister    => this == HackStatus.registrationOpen;
  bool get canSubmit      => this == HackStatus.inProgress || this == HackStatus.submissionClosed;
  bool get canVote        => this == HackStatus.votingOpen;
  bool get showTeamChat   => this == HackStatus.inProgress ||
                             this == HackStatus.submissionClosed ||
                             this == HackStatus.votingOpen ||
                             this == HackStatus.judging;
  bool get showLeaderboard => this == HackStatus.votingOpen ||
                              this == HackStatus.judging ||
                              this == HackStatus.completed ||
                              this == HackStatus.ended;
}

// ── Hackathon criterion ───────────────────────────────────────────────────────

class HackCriterion {
  final String id;
  final String name;
  final String? description;
  final int maxScore;
  final int order;

  const HackCriterion({
    required this.id,
    required this.name,
    this.description,
    required this.maxScore,
    required this.order,
  });

  factory HackCriterion.fromJson(Map<String, dynamic> j) => HackCriterion(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        maxScore: j['max_score'] as int? ?? 10,
        order: j['order'] as int? ?? 0,
      );
}

String? _parsePrizes(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return raw;
  if (raw is List) return raw.map((e) => e.toString()).join(', ');
  return raw.toString();
}

// ── Team progress ─────────────────────────────────────────────────────────────

class TeamProgress {
  final String step;
  final int percentage;
  final List<String> checklist;
  final String? notes;

  const TeamProgress({
    required this.step,
    required this.percentage,
    required this.checklist,
    this.notes,
  });

  factory TeamProgress.fromJson(Map<String, dynamic> j) {
    final rawChecklist = j['checklist'];
    final List<String> checks;
    if (rawChecklist is List) {
      checks = rawChecklist.map((e) => e.toString()).toList();
    } else if (rawChecklist is Map) {
      checks = rawChecklist.keys.map((k) => k.toString()).toList();
    } else {
      checks = [];
    }
    return TeamProgress(
      step: j['step'] as String? ?? '',
      percentage: int.tryParse(j['percentage']?.toString() ?? '0') ?? 0,
      checklist: checks,
      notes: j['notes'] as String?,
    );
  }
}

// ── HackTeamSummary (nested inside Hackathon.myTeam) ─────────────────────────

class HackTeamSummary {
  final String teamId;
  final String name;
  final String inviteCode;
  final HackTeamMember? leader;
  final List<HackTeamMember> members;
  final String status;
  final TeamProgress? progress;

  const HackTeamSummary({
    required this.teamId,
    required this.name,
    required this.inviteCode,
    this.leader,
    required this.members,
    required this.status,
    this.progress,
  });

  factory HackTeamSummary.fromJson(Map<String, dynamic> j) {
    HackTeamMember? leader;
    if (j['leader'] is Map<String, dynamic>) {
      leader = HackTeamMember.fromJson(j['leader'] as Map<String, dynamic>);
    }
    final rawMembers = j['members'] as List? ?? [];
    return HackTeamSummary(
      teamId: j['team_id'] as String? ?? j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      inviteCode: j['invite_code'] as String? ?? '',
      leader: leader,
      members: rawMembers
          .map((m) => HackTeamMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      status: j['status'] as String? ?? 'forming',
      progress: j['progress'] is Map<String, dynamic>
          ? TeamProgress.fromJson(j['progress'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Hackathon ─────────────────────────────────────────────────────────────────

class Hackathon {
  final String id;
  final String title;
  final String description;
  final String? theme;
  final HackStatus status;
  final String? bannerUrl;
  final String teamMode;
  final int minTeamSize;
  final int maxTeamSize;
  final String? prizes;
  final List<HackCriterion> criteria;
  final bool isEligible;
  final HackTeamSummary? myTeam;
  final double? judgeWeight;
  final double? peerWeight;
  final int? participantCount;
  // Dates (API field names)
  final DateTime? registrationOpensAt;
  final DateTime? registrationClosesAt;
  final DateTime? startsAt;
  final DateTime? submissionsDueAt;
  final DateTime? votingOpensAt;
  final DateTime? votingClosesAt;
  final DateTime? resultsAt;
  final DateTime? endsAt;
  final DateTime createdAt;

  const Hackathon({
    required this.id,
    required this.title,
    required this.description,
    this.theme,
    required this.status,
    this.bannerUrl,
    required this.teamMode,
    required this.minTeamSize,
    required this.maxTeamSize,
    this.prizes,
    required this.criteria,
    required this.isEligible,
    this.myTeam,
    this.judgeWeight,
    this.peerWeight,
    this.participantCount,
    this.registrationOpensAt,
    this.registrationClosesAt,
    this.startsAt,
    this.submissionsDueAt,
    this.votingOpensAt,
    this.votingClosesAt,
    this.resultsAt,
    this.endsAt,
    required this.createdAt,
  });

  // Convenience getters
  bool get isSolo      => teamMode == 'solo';
  bool get hasTeam     => myTeam != null;
  String? get myTeamId => myTeam?.teamId;
  String? get myTeamName => myTeam?.name;
  bool get isLeader    => myTeam != null &&
      myTeam!.members.any((m) => m.role == 'leader');
  bool isLeaderOf(String uid) =>
      myTeam?.members.any((m) => m.uid == uid && m.role == 'leader') == true;

  // Backwards-compat date aliases (used by existing Overview tab widgets)
  DateTime? get registrationDeadline => registrationClosesAt;
  DateTime? get submissionDeadline   => submissionsDueAt;
  DateTime? get votingDeadline       => votingOpensAt;

  factory Hackathon.fromJson(Map<String, dynamic> j) {
    final rawCriteria = j['criteria'] as List? ?? [];
    final rawTeam = j['my_team'];
    return Hackathon(
      id: j['id'] as String,
      title: j['title'] as String,
      description: j['description'] as String? ?? '',
      theme: j['theme'] as String?,
      status: HackStatusX.from(j['status'] as String? ?? ''),
      bannerUrl: j['banner_url'] as String?,
      teamMode: j['team_mode'] as String? ?? 'team',
      minTeamSize: j['min_team_size'] as int? ?? 1,
      maxTeamSize: j['max_team_size'] as int? ?? 4,
      prizes: _parsePrizes(j['prizes']),
      criteria: rawCriteria
          .map((c) => HackCriterion.fromJson(c as Map<String, dynamic>))
          .toList(),
      isEligible: j['is_eligible'] as bool? ?? j['is_registered'] as bool? ?? false,
      myTeam: rawTeam is Map<String, dynamic>
          ? HackTeamSummary.fromJson(rawTeam)
          : null,
      judgeWeight: double.tryParse(j['judge_weight']?.toString() ?? ''),
      peerWeight: double.tryParse(j['peer_weight']?.toString() ?? ''),
      participantCount: j['participant_count'] as int?,
      registrationOpensAt:
          DateTime.tryParse(j['registration_opens_at']?.toString() ?? ''),
      registrationClosesAt:
          DateTime.tryParse(j['registration_closes_at']?.toString() ??
              j['registration_deadline']?.toString() ?? ''),
      startsAt: DateTime.tryParse(j['starts_at']?.toString() ?? ''),
      submissionsDueAt:
          DateTime.tryParse(j['submissions_due_at']?.toString() ??
              j['submission_deadline']?.toString() ?? ''),
      votingOpensAt:
          DateTime.tryParse(j['voting_opens_at']?.toString() ??
              j['voting_deadline']?.toString() ?? ''),
      votingClosesAt:
          DateTime.tryParse(j['voting_closes_at']?.toString() ?? ''),
      resultsAt: DateTime.tryParse(j['results_at']?.toString() ?? ''),
      endsAt: DateTime.tryParse(j['ends_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

// ── Team member ───────────────────────────────────────────────────────────────

class HackTeamMember {
  final String uid;
  final String name;
  final String? profilePic;
  final String role;

  const HackTeamMember({
    required this.uid,
    required this.name,
    this.profilePic,
    required this.role,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory HackTeamMember.fromJson(Map<String, dynamic> j) => HackTeamMember(
        uid: j['uid'] as String? ?? j['id'] as String? ?? '',
        name: j['name'] as String? ?? j['full_name'] as String? ?? 'Unknown',
        profilePic: j['pic'] as String? ??
            j['profile_pic'] as String? ??
            j['profile_picture'] as String?,
        role: j['role'] as String? ?? 'member',
      );
}

// ── Team ──────────────────────────────────────────────────────────────────────

class HackTeam {
  final String id;
  final String hackathonId;
  final String name;
  final String inviteCode;
  final String leaderId;
  final String status;
  final List<HackTeamMember> members;
  final String? mentorRequestStatus;
  final String? mentorId;
  final double? judgeScore;
  final double? peerScore;
  final double? finalScore;
  final int? finalRank;
  final TeamProgress? progress;

  const HackTeam({
    required this.id,
    required this.hackathonId,
    required this.name,
    required this.inviteCode,
    required this.leaderId,
    required this.status,
    required this.members,
    this.mentorRequestStatus,
    this.mentorId,
    this.judgeScore,
    this.peerScore,
    this.finalScore,
    this.finalRank,
    this.progress,
  });

  bool get hasMentor => mentorRequestStatus == 'accepted' && mentorId != null;

  factory HackTeam.fromJson(Map<String, dynamic> j) {
    final rawMembers = j['members'] as List? ?? [];
    return HackTeam(
      id: j['id'] as String? ?? j['team_id'] as String? ?? '',
      hackathonId: j['hackathon_id'] as String? ?? '',
      name: j['name'] as String,
      inviteCode: j['invite_code'] as String? ?? '',
      leaderId: j['leader_id'] as String? ??
          (j['leader'] as Map<String, dynamic>?)?['uid'] as String? ?? '',
      status: j['status'] as String? ?? 'active',
      members: rawMembers
          .map((m) => HackTeamMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      mentorRequestStatus: j['mentor_request_status'] as String?,
      mentorId: j['mentor_id'] as String?,
      judgeScore: double.tryParse(j['judge_score']?.toString() ?? ''),
      peerScore: double.tryParse(j['peer_score']?.toString() ?? ''),
      finalScore: double.tryParse(j['final_score']?.toString() ?? ''),
      finalRank: j['final_rank'] as int?,
      progress: j['progress'] is Map<String, dynamic>
          ? TeamProgress.fromJson(j['progress'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Open team ─────────────────────────────────────────────────────────────────

class OpenTeam {
  final String teamId;
  final String name;
  final String inviteCode;
  final String leaderName;
  final int membersCount;
  final int slotsLeft;

  const OpenTeam({
    required this.teamId,
    required this.name,
    required this.inviteCode,
    required this.leaderName,
    required this.membersCount,
    required this.slotsLeft,
  });

  factory OpenTeam.fromJson(Map<String, dynamic> j) {
    final leader = j['leader'] as Map<String, dynamic>?;
    return OpenTeam(
      teamId: j['team_id'] as String,
      name: j['name'] as String,
      inviteCode: j['invite_code'] as String? ?? '',
      leaderName: leader?['full_name'] as String? ??
          leader?['name'] as String? ?? 'Unknown',
      membersCount: int.tryParse(j['members_count']?.toString() ?? '0') ?? 0,
      slotsLeft: int.tryParse(j['slots_left']?.toString() ?? '0') ?? 0,
    );
  }
}

// ── Submission ────────────────────────────────────────────────────────────────

class HackSubmission {
  final String id;
  final String projectName;
  final String description;
  final String? repoUrl;
  final String? demoUrl;
  final String? videoUrl;
  final List<String> additionalLinks;
  final bool isFinalised;
  final String? teamName;
  final DateTime? submittedAt;

  const HackSubmission({
    required this.id,
    required this.projectName,
    required this.description,
    this.repoUrl,
    this.demoUrl,
    this.videoUrl,
    required this.additionalLinks,
    required this.isFinalised,
    this.teamName,
    this.submittedAt,
  });

  factory HackSubmission.fromJson(Map<String, dynamic> j) {
    final rawLinks = j['additional_links'];
    final List<String> links = rawLinks is List
        ? rawLinks.map((e) => e.toString()).toList()
        : [];
    final team = j['team'] as Map<String, dynamic>?;
    return HackSubmission(
      id: j['id'] as String,
      projectName: j['project_name'] as String,
      description: j['description'] as String? ?? '',
      repoUrl: j['repo_url'] as String?,
      demoUrl: j['demo_url'] as String?,
      videoUrl: j['video_url'] as String?,
      additionalLinks: links,
      isFinalised: j['is_finalised'] as bool? ??
          j['is_final'] as bool? ?? false,
      teamName: team?['name'] as String? ?? j['team_name'] as String?,
      submittedAt: DateTime.tryParse(j['submitted_at']?.toString() ?? ''),
    );
  }
}

// ── Discussion comment ────────────────────────────────────────────────────────

class DiscussionComment {
  final String id;
  final String hackathonId;
  final String userId;
  final String userName;
  final String? userProfilePic;
  final String? userBadge;
  final String body;
  final int likesCount;
  final bool likedByMe;
  final int repliesCount;
  final bool hasMoreReplies;
  final List<DiscussionComment> replies;
  final DiscussionReplyTo? replyTo;
  final DateTime createdAt;

  const DiscussionComment({
    required this.id,
    required this.hackathonId,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    this.userBadge,
    required this.body,
    required this.likesCount,
    required this.likedByMe,
    required this.repliesCount,
    required this.hasMoreReplies,
    required this.replies,
    this.replyTo,
    required this.createdAt,
  });

  String get initials {
    final parts = userName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  factory DiscussionComment.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    final rawReplies = j['replies'] as List? ?? [];
    DiscussionReplyTo? replyTo;
    if (j['reply_to'] is Map<String, dynamic>) {
      replyTo = DiscussionReplyTo.fromJson(j['reply_to'] as Map<String, dynamic>);
    }
    return DiscussionComment(
      id: j['id'] as String,
      hackathonId: j['hackathon_id'] as String? ?? '',
      userId: user?['uid'] as String? ?? user?['id'] as String? ??
          j['user_id'] as String? ?? '',
      userName: user?['name'] as String? ?? user?['full_name'] as String? ??
          j['user_name'] as String? ?? 'Unknown',
      userProfilePic: user?['pic'] as String? ??
          user?['profile_pic'] as String? ??
          user?['profile_picture'] as String?,
      userBadge: user?['badge'] as String?,
      body: j['body'] as String,
      // API sends like_count, is_liked, reply_count
      likesCount: int.tryParse(j['like_count']?.toString() ?? '0') ?? 0,
      likedByMe: j['is_liked'] as bool? ?? false,
      repliesCount: int.tryParse(j['reply_count']?.toString() ?? '0') ?? 0,
      hasMoreReplies: j['has_more_replies'] as bool? ?? false,
      replies: rawReplies
          .map((r) => DiscussionComment.fromJson(r as Map<String, dynamic>))
          .toList(),
      replyTo: replyTo,
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  DiscussionComment copyWith({bool? likedByMe, int? likesCount}) =>
      DiscussionComment(
        id: id,
        hackathonId: hackathonId,
        userId: userId,
        userName: userName,
        userProfilePic: userProfilePic,
        userBadge: userBadge,
        body: body,
        likesCount: likesCount ?? this.likesCount,
        likedByMe: likedByMe ?? this.likedByMe,
        repliesCount: repliesCount,
        hasMoreReplies: hasMoreReplies,
        replies: replies,
        replyTo: replyTo,
        createdAt: createdAt,
      );
}

class DiscussionReplyTo {
  final String uid;
  final String name;

  const DiscussionReplyTo({required this.uid, required this.name});

  factory DiscussionReplyTo.fromJson(Map<String, dynamic> j) =>
      DiscussionReplyTo(
        uid: j['uid'] as String? ?? '',
        name: j['name'] as String? ?? '',
      );
}

// ── Mentor message ────────────────────────────────────────────────────────────

class MentorMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderProfilePic;
  final String body;
  final DateTime? createdAt;

  const MentorMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderProfilePic,
    required this.body,
    this.createdAt,
  });

  factory MentorMessage.fromJson(Map<String, dynamic> j) => MentorMessage(
        id: j['id'] as String,
        senderId: j['sender_id'] as String,
        senderName: j['sender_name'] as String,
        senderProfilePic: j['sender_profile_pic'] as String?,
        body: j['body'] as String,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );
}

// ── Leaderboard entry ─────────────────────────────────────────────────────────

class HackLeaderboardEntry {
  final String teamId;
  final String teamName;
  final String projectName;
  final int peerVotes;
  final int? finalRank;
  final int? rank;
  final double? finalScore;
  final double? judgeScore;
  final double? peerScore;

  const HackLeaderboardEntry({
    required this.teamId,
    required this.teamName,
    required this.projectName,
    required this.peerVotes,
    this.finalRank,
    this.rank,
    this.finalScore,
    this.judgeScore,
    this.peerScore,
  });

  int get displayRank => rank ?? finalRank ?? 0;

  factory HackLeaderboardEntry.fromJson(Map<String, dynamic> j) =>
      HackLeaderboardEntry(
        teamId: j['team_id'] as String,
        teamName: j['team_name'] as String? ?? j['name'] as String? ?? '',
        projectName: j['project_name'] as String? ?? '',
        peerVotes: int.tryParse(
                j['vote_count']?.toString() ??
                j['peer_votes']?.toString() ?? '0') ?? 0,
        finalRank: j['final_rank'] as int?,
        rank: j['rank'] as int?,
        finalScore: double.tryParse(j['final_score']?.toString() ?? ''),
        judgeScore: double.tryParse(j['judge_score']?.toString() ?? ''),
        peerScore: double.tryParse(j['peer_score']?.toString() ?? ''),
      );
}

// ── Vote status ───────────────────────────────────────────────────────────────

class VoteStatus {
  final bool canVote;
  final String reason;
  final String? votedFor;
  final List<HackLeaderboardEntry> leaderboard;

  const VoteStatus({
    required this.canVote,
    required this.reason,
    this.votedFor,
    required this.leaderboard,
  });

  bool get hasVoted => votedFor != null;

  factory VoteStatus.fromJson(Map<String, dynamic> j) {
    final votedForRaw = j['voted_for']?.toString();
    return VoteStatus(
      canVote: j['can_vote'] == true || j['can_vote'] == 'true',
      reason: j['reason'] as String? ?? '',
      votedFor: (votedForRaw?.isNotEmpty == true) ? votedForRaw : null,
      leaderboard: (j['leaderboard'] as List? ?? [])
          .map((e) => HackLeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Team chat message ─────────────────────────────────────────────────────────

class HackTeamMessageSender {
  final String uid;
  final String name;
  final String? profilePic;

  const HackTeamMessageSender({
    required this.uid,
    required this.name,
    this.profilePic,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory HackTeamMessageSender.fromJson(Map<String, dynamic> j) =>
      HackTeamMessageSender(
        uid: j['uid'] as String? ?? '',
        name: j['name'] as String? ?? 'Unknown',
        profilePic: j['profile_pic'] as String?,
      );
}

class HackTeamReplyContext {
  final String id;
  final String senderName;
  final String body;
  final String type;

  const HackTeamReplyContext({
    required this.id,
    required this.senderName,
    required this.body,
    required this.type,
  });

  factory HackTeamReplyContext.fromJson(Map<String, dynamic> j) =>
      HackTeamReplyContext(
        id: j['id'] as String? ?? '',
        senderName: j['sender_name'] as String? ?? '',
        body: j['body'] as String? ?? '',
        type: j['type'] as String? ?? 'text',
      );
}

class HackTeamAttachment {
  final String url;
  final String? type;
  final String? name;
  final String? mimeType;

  const HackTeamAttachment({
    required this.url,
    this.type,
    this.name,
    this.mimeType,
  });

  bool get isImage =>
      type == 'image' ||
      url.endsWith('.jpg') ||
      url.endsWith('.jpeg') ||
      url.endsWith('.png') ||
      url.endsWith('.gif') ||
      url.endsWith('.webp');

  factory HackTeamAttachment.fromJson(Map<String, dynamic> j) =>
      HackTeamAttachment(
        url: j['url'] as String? ?? '',
        type: j['type'] as String?,
        name: j['filename'] as String? ?? j['name'] as String?,
        mimeType: j['mime_type'] as String?,
      );
}

class HackTeamMessage {
  final String id;
  final String hackathonId;
  final String teamId;
  final HackTeamMessageSender sender;
  final String body;
  final String type;
  final List<HackTeamAttachment> attachments;
  final Map<String, List<String>> reactions;
  final HackTeamReplyContext? replyTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPending;
  final bool isFailed;

  const HackTeamMessage({
    required this.id,
    required this.hackathonId,
    required this.teamId,
    required this.sender,
    required this.body,
    required this.type,
    required this.attachments,
    required this.reactions,
    this.replyTo,
    required this.createdAt,
    required this.updatedAt,
    this.isPending = false,
    this.isFailed = false,
  });

  HackTeamMessage copyWith({
    String? id,
    Map<String, List<String>>? reactions,
    bool? isPending,
    bool? isFailed,
  }) =>
      HackTeamMessage(
        id: id ?? this.id,
        hackathonId: hackathonId,
        teamId: teamId,
        sender: sender,
        body: body,
        type: type,
        attachments: attachments,
        reactions: reactions ?? this.reactions,
        replyTo: replyTo,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isPending: isPending ?? this.isPending,
        isFailed: isFailed ?? this.isFailed,
      );

  factory HackTeamMessage.fromJson(Map<String, dynamic> j) {
    final rawAtts = j['attachments'] as List? ?? [];
    final rawReactions = j['reactions'];
    Map<String, List<String>> reactions = {};
    if (rawReactions is Map) {
      reactions = rawReactions.map((k, v) => MapEntry(
            k.toString(),
            v is List ? v.map((e) => e.toString()).toList() : [v.toString()],
          ));
    }
    HackTeamReplyContext? replyTo;
    if (j['reply_to'] is Map<String, dynamic>) {
      replyTo = HackTeamReplyContext.fromJson(
          j['reply_to'] as Map<String, dynamic>);
    }
    return HackTeamMessage(
      id: j['id'] as String? ?? '',
      hackathonId: j['hackathon_id'] as String? ?? '',
      teamId: j['team_id'] as String? ?? '',
      sender: HackTeamMessageSender.fromJson(
        Map<String, dynamic>.from(j['sender'] as Map? ?? {}),
      ),
      body: j['body'] as String? ?? '',
      type: j['type'] as String? ?? 'text',
      attachments: rawAtts
          .map((a) => HackTeamAttachment.fromJson(a as Map<String, dynamic>))
          .toList(),
      reactions: reactions,
      replyTo: replyTo,
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(j['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
