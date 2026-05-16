// lib/features/study_groups/models/study_group_models.dart

class StudyGroupCreator {
  final String id;
  final String name;

  const StudyGroupCreator({required this.id, required this.name});

  factory StudyGroupCreator.fromJson(Map<String, dynamic> j) =>
      StudyGroupCreator(
        id: j['id'] as String,
        name: j['name'] as String,
      );
}

// ── Core StudyGroup model ────────────────────────────────────────────────────

class StudyGroup {
  final String id;
  final String name;
  final String? description;
  final String? subject;
  final bool isPublic;
  final bool adminOnlyMessaging;
  final int capacity;
  final int memberCount;
  final bool isFull;
  final bool isMember;
  final String? role; // creator | admin | member | null
  final String? conversationId;
  final StudyGroupCreator? createdBy;
  final DateTime? createdAt;

  const StudyGroup({
    required this.id,
    required this.name,
    this.description,
    this.subject,
    required this.isPublic,
    required this.adminOnlyMessaging,
    required this.capacity,
    required this.memberCount,
    required this.isFull,
    required this.isMember,
    this.role,
    this.conversationId,
    this.createdBy,
    this.createdAt,
  });

  bool get isCreator => role == 'creator';
  bool get isAdmin => role == 'creator' || role == 'admin';
  double get fillRatio => capacity > 0 ? memberCount / capacity : 0;

  factory StudyGroup.fromJson(Map<String, dynamic> j) => StudyGroup(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        subject: j['subject'] as String?,
        isPublic: j['is_public'] as bool? ?? true,
        adminOnlyMessaging: j['admin_only_messaging'] as bool? ?? false,
        capacity: j['capacity'] as int? ?? 15,
        memberCount:
            int.tryParse(j['member_count']?.toString() ?? '0') ?? 0,
        isFull: j['is_full'] as bool? ?? false,
        isMember: j['is_member'] as bool? ?? false,
        role: j['role'] as String?,
        conversationId: j['conversation_id'] as String?,
        createdBy: j['created_by'] != null
            ? StudyGroupCreator.fromJson(
                j['created_by'] as Map<String, dynamic>)
            : null,
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );
}

// ── Member ────────────────────────────────────────────────────────────────────

class GroupMember {
  final String id;
  final String name;
  final String? profilePic;
  final String role; // creator | admin | member
  final DateTime? joinedAt;

  const GroupMember({
    required this.id,
    required this.name,
    this.profilePic,
    required this.role,
    this.joinedAt,
  });

  bool get isCreator => role == 'creator';
  bool get isAdmin => role == 'creator' || role == 'admin';

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
        id: j['id'] as String? ?? j['uid'] as String? ?? '',
        name: j['full_name'] as String? ??
            j['name'] as String? ??
            'Unknown',
        profilePic: j['profile_picture'] as String? ??
            j['profile_pic'] as String?,
        role: j['role'] as String? ?? 'member',
        joinedAt: DateTime.tryParse(j['joined_at']?.toString() ?? ''),
      );
}

// ── Join Request ──────────────────────────────────────────────────────────────

class JoinRequest {
  final String id;
  final String studyGroupId;
  final String userId;
  final String userName;
  final String? userProfilePic;
  final String status; // pending | approved | rejected
  final DateTime createdAt;

  const JoinRequest({
    required this.id,
    required this.studyGroupId,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  String get initials {
    final parts = userName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  factory JoinRequest.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return JoinRequest(
      id: j['id'] as String,
      studyGroupId: j['study_group_id'] as String? ?? '',
      userId: user?['id'] as String? ??
          user?['uid'] as String? ??
          j['user_id'] as String? ?? '',
      userName: user?['full_name'] as String? ??
          user?['name'] as String? ??
          j['user_name'] as String? ?? 'Unknown',
      userProfilePic: user?['profile_picture'] as String? ??
          user?['profile_pic'] as String?,
      status: j['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

// ── Invite ────────────────────────────────────────────────────────────────────

class GroupInvite {
  final String id;
  final String token;
  final String status; // pending | accepted | declined | expired
  final String? studyGroupId;
  final String? studyGroupName;
  final String? invitedByName;
  final String? inviteeName;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const GroupInvite({
    required this.id,
    required this.token,
    required this.status,
    this.studyGroupId,
    this.studyGroupName,
    this.invitedByName,
    this.inviteeName,
    this.expiresAt,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory GroupInvite.fromJson(Map<String, dynamic> j) {
    final sg = j['study_group'] as Map<String, dynamic>?;
    final invitedBy = j['invited_by'] as Map<String, dynamic>?;
    final invitee = j['invitee'] as Map<String, dynamic>?;
    return GroupInvite(
      id: j['id'] as String,
      token: j['token'] as String? ?? '',
      status: j['status'] as String? ?? 'pending',
      studyGroupId: sg?['id'] as String? ?? j['study_group_id'] as String?,
      studyGroupName: sg?['name'] as String? ?? j['study_group_name'] as String?,
      invitedByName: invitedBy?['full_name'] as String? ??
          invitedBy?['name'] as String?,
      inviteeName: invitee?['full_name'] as String? ??
          invitee?['name'] as String?,
      expiresAt:
          DateTime.tryParse(j['expires_at']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}
