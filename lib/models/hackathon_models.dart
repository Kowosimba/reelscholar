// lib/models/hackathon_models.dart

import 'package:flutter/material.dart';

// ── Status helpers ────────────────────────────────────────────────────────────

enum HackStatus { draft, published, ongoing, submission, voting, judging, ended }

extension HackStatusX on HackStatus {
  static HackStatus from(String s) {
    switch (s.toLowerCase()) {
      case 'published': return HackStatus.published;
      case 'ongoing': return HackStatus.ongoing;
      case 'submission': return HackStatus.submission;
      case 'voting': return HackStatus.voting;
      case 'judging': return HackStatus.judging;
      case 'ended': return HackStatus.ended;
      default: return HackStatus.draft;
    }
  }

  String get label {
    switch (this) {
      case HackStatus.published: return 'Registration Open';
      case HackStatus.ongoing: return 'In Progress';
      case HackStatus.submission: return 'Submissions Open';
      case HackStatus.voting: return 'Voting';
      case HackStatus.judging: return 'Judging';
      case HackStatus.ended: return 'Ended';
      default: return 'Draft';
    }
  }

  Color get color {
    switch (this) {
      case HackStatus.published: return const Color(0xFF22C55E);
      case HackStatus.ongoing: return const Color(0xFF3B82F6);
      case HackStatus.submission: return const Color(0xFF6366F1);
      case HackStatus.voting: return const Color(0xFFF59E0B);
      case HackStatus.judging: return const Color(0xFFEC4899);
      case HackStatus.ended: return const Color(0xFF64748B);
      default: return const Color(0xFF94A3B8);
    }
  }

  Color get bg {
    switch (this) {
      case HackStatus.published: return const Color(0xFFDCFCE7);
      case HackStatus.ongoing: return const Color(0xFFDBEAFE);
      case HackStatus.submission: return const Color(0xFFEDE9FE);
      case HackStatus.voting: return const Color(0xFFFEF3C7);
      case HackStatus.judging: return const Color(0xFFFCE7F3);
      case HackStatus.ended: return const Color(0xFFF1F5F9);
      default: return const Color(0xFFF8FAFC);
    }
  }

  bool get canRegister => this == HackStatus.published;
  bool get canSubmit => this == HackStatus.submission || this == HackStatus.ongoing;
  bool get canVote => this == HackStatus.voting;
  bool get showLeaderboard => this == HackStatus.voting || this == HackStatus.judging || this == HackStatus.ended;
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

// ── Hackathon ────────────────────────────────────────────────────────────────

class Hackathon {
  final String id;
  final String title;
  final String description;
  final String? theme;
  final HackStatus status;
  final String? bannerUrl;
  final String teamMode; // solo | team
  final int minTeamSize;
  final int maxTeamSize;
  final String? prizes;
  final List<HackCriterion> criteria;
  final DateTime? registrationDeadline;
  final DateTime? submissionDeadline;
  final DateTime? votingDeadline;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;
  // Current user context
  final bool isRegistered;
  final String? myTeamId;
  final String? myTeamName;
  final String? myRole; // leader | member
  final int? participantCount;

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
    this.registrationDeadline,
    this.submissionDeadline,
    this.votingDeadline,
    this.startsAt,
    this.endsAt,
    required this.createdAt,
    required this.isRegistered,
    this.myTeamId,
    this.myTeamName,
    this.myRole,
    this.participantCount,
  });

  bool get isSolo => teamMode == 'solo';
  bool get isLeader => myRole == 'leader';
  bool get hasTeam => myTeamId != null;

  factory Hackathon.fromJson(Map<String, dynamic> j) {
    final rawCriteria = j['criteria'] as List? ?? [];
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
      registrationDeadline:
          DateTime.tryParse(j['registration_deadline']?.toString() ?? ''),
      submissionDeadline:
          DateTime.tryParse(j['submission_deadline']?.toString() ?? ''),
      votingDeadline:
          DateTime.tryParse(j['voting_deadline']?.toString() ?? ''),
      startsAt: DateTime.tryParse(j['starts_at']?.toString() ?? ''),
      endsAt: DateTime.tryParse(j['ends_at']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ??
              DateTime.now(),
      isRegistered: j['is_registered'] as bool? ?? false,
      myTeamId: j['my_team_id'] as String?,
      myTeamName: j['my_team_name'] as String?,
      myRole: j['my_role'] as String?,
      participantCount: j['participant_count'] as int?,
    );
  }
}

// ── Team member ───────────────────────────────────────────────────────────────

class HackTeamMember {
  final String uid;
  final String name;
  final String? profilePic;
  final String role; // leader | member

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
        profilePic:
            j['profile_pic'] as String? ?? j['profile_picture'] as String?,
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
  final int? progress;

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

  bool get hasMentor =>
      mentorRequestStatus == 'accepted' && mentorId != null;

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
      judgeScore:
          double.tryParse(j['judge_score']?.toString() ?? ''),
      peerScore:
          double.tryParse(j['peer_score']?.toString() ?? ''),
      finalScore:
          double.tryParse(j['final_score']?.toString() ?? ''),
      finalRank: j['final_rank'] as int?,
      progress: int.tryParse(j['progress']?.toString() ?? ''),
    );
  }
}

// ── Open team (for browsing) ──────────────────────────────────────────────────

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
      membersCount:
          int.tryParse(j['members_count']?.toString() ?? '0') ?? 0,
      slotsLeft:
          int.tryParse(j['slots_left']?.toString() ?? '0') ?? 0,
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
    List<String> links = [];
    if (rawLinks is List) {
      links = rawLinks.map((e) => e.toString()).toList();
    }
    final team = j['team'] as Map<String, dynamic>?;
    return HackSubmission(
      id: j['id'] as String,
      projectName: j['project_name'] as String,
      description: j['description'] as String? ?? '',
      repoUrl: j['repo_url'] as String?,
      demoUrl: j['demo_url'] as String?,
      videoUrl: j['video_url'] as String?,
      additionalLinks: links,
      isFinalised: j['is_finalised'] as bool? ?? false,
      teamName: team?['name'] as String? ?? j['team_name'] as String?,
      submittedAt:
          DateTime.tryParse(j['submitted_at']?.toString() ?? ''),
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
  final String body;
  final int likesCount;
  final bool likedByMe;
  final int repliesCount;
  final List<DiscussionComment> replies;
  final DateTime createdAt;

  const DiscussionComment({
    required this.id,
    required this.hackathonId,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    required this.body,
    required this.likesCount,
    required this.likedByMe,
    required this.repliesCount,
    required this.replies,
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
    return DiscussionComment(
      id: j['id'] as String,
      hackathonId: j['hackathon_id'] as String? ?? '',
      userId: user?['uid'] as String? ??
          user?['id'] as String? ??
          j['user_id'] as String? ?? '',
      userName: user?['full_name'] as String? ??
          user?['name'] as String? ??
          j['user_name'] as String? ?? 'Unknown',
      userProfilePic: user?['profile_picture'] as String? ??
          user?['profile_pic'] as String?,
      body: j['body'] as String,
      likesCount:
          int.tryParse(j['likes_count']?.toString() ?? '0') ?? 0,
      likedByMe: j['liked_by_me'] as bool? ?? false,
      repliesCount:
          int.tryParse(j['replies_count']?.toString() ?? '0') ?? 0,
      replies: rawReplies
          .map((r) =>
              DiscussionComment.fromJson(r as Map<String, dynamic>))
          .toList(),
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ??
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
        body: body,
        likesCount: likesCount ?? this.likesCount,
        likedByMe: likedByMe ?? this.likedByMe,
        repliesCount: repliesCount,
        replies: replies,
        createdAt: createdAt,
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
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );
}

// ── Leaderboard entry ─────────────────────────────────────────────────────────

class HackLeaderboardEntry {
  final String teamId;
  final String teamName;
  final String projectName;
  final int peerVotes;
  final int? finalRank;
  final double? finalScore;
  final double? judgeScore;
  final double? peerScore;

  const HackLeaderboardEntry({
    required this.teamId,
    required this.teamName,
    required this.projectName,
    required this.peerVotes,
    this.finalRank,
    this.finalScore,
    this.judgeScore,
    this.peerScore,
  });

  factory HackLeaderboardEntry.fromJson(Map<String, dynamic> j) =>
      HackLeaderboardEntry(
        teamId: j['team_id'] as String,
        teamName: j['team_name'] as String,
        projectName: j['project_name'] as String? ?? '',
        peerVotes:
            int.tryParse(j['peer_votes']?.toString() ?? '0') ?? 0,
        finalRank: j['final_rank'] as int?,
        finalScore:
            double.tryParse(j['final_score']?.toString() ?? ''),
        judgeScore:
            double.tryParse(j['judge_score']?.toString() ?? ''),
        peerScore:
            double.tryParse(j['peer_score']?.toString() ?? ''),
      );
}

// ── Vote status ───────────────────────────────────────────────────────────────

class VoteStatus {
  final bool canVote;
  final String reason;
  final bool hasVoted;
  final String? votedFor;

  const VoteStatus({
    required this.canVote,
    required this.reason,
    required this.hasVoted,
    this.votedFor,
  });

  factory VoteStatus.fromJson(Map<String, dynamic> j) => VoteStatus(
        canVote: j['can_vote'] == true || j['can_vote'] == 'true',
        reason: j['reason'] as String? ?? '',
        hasVoted: j['has_voted'] as bool? ?? false,
        votedFor: j['voted_for'] as String?,
      );
}
