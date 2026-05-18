// lib/features/social/models/social_models.dart

class AppUser {
  final String uid;
  final String fullName;
  final String? studentId;
  final String? faculty;
  final String? degreeProgramme;
  final String role; // student | lecturer
  final String? bio;
  final String? profilePicUrl;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int videoCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool followsYou;
  final bool isBlocked;

  const AppUser({
    required this.uid,
    required this.fullName,
    this.studentId,
    this.faculty,
    this.degreeProgramme,
    required this.role,
    this.bio,
    this.profilePicUrl,
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.videoCount,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    required this.followsYou,
    required this.isBlocked,
  });

  bool get isLecturer => role == 'lecturer';

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  int get xpLevel => (totalXp / 500).floor() + 1;
  double get xpProgress => (totalXp % 500) / 500;

  static bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v == 'true' || v == '1';
    if (v is int) return v == 1;
    return false;
  }

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        uid: j['uid'] as String?
            ?? j['firebase_uid'] as String?
            ?? j['id']?.toString()
            ?? j['user_id']?.toString()
            ?? '',
        fullName: j['full_name'] as String? ?? j['name'] as String? ?? 'Unknown',
        studentId: j['student_id'] as String?,
        faculty: j['faculty'] as String?,
        degreeProgramme: j['degree_programme'] as String?,
        role: j['role'] as String? ?? 'student',
        bio: j['bio'] as String?,
        profilePicUrl: j['profile_pic_url'] as String? ??
            j['profile_picture'] as String?,
        totalXp: int.tryParse(j['total_xp']?.toString() ?? '0') ?? 0,
        currentStreak:
            int.tryParse(j['current_streak']?.toString() ?? '0') ?? 0,
        longestStreak:
            int.tryParse(j['longest_streak']?.toString() ?? '0') ?? 0,
        videoCount:
            int.tryParse(j['video_count']?.toString() ?? '0') ?? 0,
        followersCount:
            int.tryParse(j['followers_count']?.toString() ??
                j['followers']?.toString() ??
                '0') ?? 0,
        followingCount:
            int.tryParse(j['following_count']?.toString() ??
                j['following']?.toString() ??
                '0') ?? 0,
        isFollowing: _parseBool(j['is_following']),
        followsYou: _parseBool(j['follows_you']),
        isBlocked: _parseBool(j['is_blocked']),
      );

  AppUser copyWith({bool? isFollowing, int? followersCount, bool? isBlocked}) =>
      AppUser(
        uid: uid,
        fullName: fullName,
        studentId: studentId,
        faculty: faculty,
        degreeProgramme: degreeProgramme,
        role: role,
        bio: bio,
        profilePicUrl: profilePicUrl,
        totalXp: totalXp,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        videoCount: videoCount,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount,
        isFollowing: isFollowing ?? this.isFollowing,
        followsYou: followsYou,
        isBlocked: isBlocked ?? this.isBlocked,
      );
}
