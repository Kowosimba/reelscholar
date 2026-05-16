// ─── Uploader (embedded in ReelResource) ──────────────────────────────────────
class ReelUploader {
  final String uid;
  final String fullName;
  final String? profilePicUrl;
  final bool isFollowing;

  const ReelUploader({
    required this.uid,
    required this.fullName,
    this.profilePicUrl,
    required this.isFollowing,
  });

  factory ReelUploader.fromJson(Map<String, dynamic> j) => ReelUploader(
    uid: j['uid'] as String? ?? '',
    fullName: (j['full_name'] ?? j['name'] ?? j['display_name'] ?? j['username'] ?? '') as String,
    profilePicUrl: j['profile_pic_url'] as String?,
    isFollowing: j['is_following'] as bool? ?? false,
  );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ─── Topic (embedded in ReelResource) ─────────────────────────────────────────
class ReelTopic {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  const ReelTopic({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory ReelTopic.fromJson(Map<String, dynamic> j) => ReelTopic(
    id: j['id'] as int? ?? 0,
    name: j['name'] as String? ?? '',
    slug: j['slug'] as String? ?? '',
    icon: j['icon'] as String?,
  );
}

// ─── Hashtag ──────────────────────────────────────────────────────────────────
class Hashtag {
  final int id;
  final String name;
  final int usageCount;

  const Hashtag({
    required this.id,
    required this.name,
    required this.usageCount,
  });

  factory Hashtag.fromJson(Map<String, dynamic> j) => Hashtag(
    id: j['id'] as int? ?? 0,
    name: j['name'] as String? ?? '',
    usageCount: j['usage_count'] as int? ?? 0,
  );
}

// ─── Reel ─────────────────────────────────────────────────────────────────────
class Reel {
  final String id;
  final ReelUploader uploader;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? caption;
  final List<String> hashtags;
  final ReelTopic? topic;
  final String? audience;
  final int? duration; // seconds
  int likeCount;
  int commentCount;
  int viewCount;
  int shareCount;
  int bookmarkCount;
  bool isLiked;
  bool isBookmarked;
  final DateTime createdAt;

  Reel({
    required this.id,
    required this.uploader,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
    required this.hashtags,
    this.topic,
    this.audience,
    this.duration,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.shareCount,
    required this.bookmarkCount,
    required this.isLiked,
    required this.isBookmarked,
    required this.createdAt,
  });

  factory Reel.fromJson(Map<String, dynamic> j) {
    List<String> tags = [];
    final rawTags = j['hashtags'];
    if (rawTags is List) {
      tags = rawTags
          .map((t) {
            if (t is String) return t;
            if (t is Map) return t['name'] as String? ?? '';
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return Reel(
      id: j['id']?.toString() ?? '',
      uploader: ReelUploader.fromJson(
        j['uploader'] as Map<String, dynamic>? ?? {},
      ),
      videoUrl: j['video_url'] as String? ?? '',
      thumbnailUrl: j['thumbnail_url'] as String?,
      caption: j['caption'] as String?,
      hashtags: tags,
      topic: j['topic'] != null
          ? ReelTopic.fromJson(j['topic'] as Map<String, dynamic>)
          : null,
      audience: j['audience'] as String?,
      duration: j['duration'] as int?,
      likeCount: j['like_count'] as int? ?? 0,
      commentCount: j['comment_count'] as int? ?? 0,
      viewCount: j['view_count'] as int? ?? 0,
      shareCount: j['share_count'] as int? ?? 0,
      bookmarkCount: j['bookmark_count'] as int? ?? 0,
      isLiked: j['is_liked'] as bool? ?? false,
      isBookmarked: j['is_bookmarked'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Reel copyWith({
    bool? isLiked,
    bool? isBookmarked,
    int? likeCount,
    int? bookmarkCount,
    int? commentCount,
    int? viewCount,
    int? shareCount,
  }) => Reel(
    id: id,
    uploader: uploader,
    videoUrl: videoUrl,
    thumbnailUrl: thumbnailUrl,
    caption: caption,
    hashtags: hashtags,
    topic: topic,
    audience: audience,
    duration: duration,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount ?? this.commentCount,
    viewCount: viewCount ?? this.viewCount,
    shareCount: shareCount ?? this.shareCount,
    bookmarkCount: bookmarkCount ?? this.bookmarkCount,
    isLiked: isLiked ?? this.isLiked,
    isBookmarked: isBookmarked ?? this.isBookmarked,
    createdAt: createdAt,
  );
}

// ─── Comment ──────────────────────────────────────────────────────────────────
class ReelComment {
  final String id;
  final CommentUser user;
  final String body;
  int likeCount;
  final int replyCount;
  bool isLiked;
  final bool isCreatorComment;
  final CommentUser? replyTo;
  List<ReelComment> replies;
  final bool hasMoreReplies;
  final DateTime createdAt;

  ReelComment({
    required this.id,
    required this.user,
    required this.body,
    required this.likeCount,
    required this.replyCount,
    required this.isLiked,
    required this.isCreatorComment,
    this.replyTo,
    required this.replies,
    required this.hasMoreReplies,
    required this.createdAt,
  });

  factory ReelComment.fromJson(Map<String, dynamic> j) {
    final repliesRaw = j['replies'] as List<dynamic>? ?? [];
    return ReelComment(
      id: j['id']?.toString() ?? '',
      user: CommentUser.fromJson(j['user'] as Map<String, dynamic>? ?? {}),
      body: j['body'] as String? ?? '',
      likeCount: j['like_count'] as int? ?? 0,
      replyCount: j['reply_count'] as int? ?? 0,
      isLiked: j['is_liked'] as bool? ?? false,
      isCreatorComment: j['is_creator_comment'] as bool? ?? false,
      replyTo: j['reply_to'] != null
          ? CommentUser.fromJson(j['reply_to'] as Map<String, dynamic>)
          : null,
      replies: repliesRaw
          .map((r) => ReelComment.fromJson(r as Map<String, dynamic>))
          .toList(),
      hasMoreReplies: j['has_more_replies'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class CommentUser {
  final String uid;
  final String fullName;
  final String? profilePicUrl;

  const CommentUser({
    required this.uid,
    required this.fullName,
    this.profilePicUrl,
  });

  factory CommentUser.fromJson(Map<String, dynamic> j) => CommentUser(
    uid: j['uid'] as String? ?? '',
    fullName: (j['full_name'] ?? j['name'] ?? j['display_name'] ?? j['username'] ?? '') as String,
    profilePicUrl: j['profile_pic_url'] as String?,
  );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ─── Pagination meta ──────────────────────────────────────────────────────────
class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginationMeta.fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return const PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        total: 0,
        perPage: 15,
      );
    }
    return PaginationMeta(
      currentPage: j['current_page'] as int? ?? 1,
      lastPage: j['last_page'] as int? ?? 1,
      total: j['total'] as int? ?? 0,
      perPage: j['per_page'] as int? ?? 15,
    );
  }
}
