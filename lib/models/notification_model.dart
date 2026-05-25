enum NotifType {
  like,
  comment,
  commentReply,
  commentMention,
  follow,
  messageRequestReceived,
  messageRequestAccepted,
  messageRequestRejected,
  studyGroupInvite,
  studyGroupInviteAccepted,
  studyGroupInviteDeclined,
  studyGroupJoinRequest,
  studyGroupJoinApproved,
  studyGroupJoinRejected,
  hackathonStarted,
  achievement,
  learning,
  system,
}

class AppNotification {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: _typeFromString(json['type']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  String get timeLabel {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

NotifType _typeFromString(String t) => switch (t) {
      'like' || 'reel_like' => NotifType.like,
      'comment' || 'reel_comment' => NotifType.comment,
      'reel_comment_reply' => NotifType.commentReply,
      'reel_comment_mention' => NotifType.commentMention,
      'follow' || 'new_follower' => NotifType.follow,
      'message_request_received' => NotifType.messageRequestReceived,
      'message_request_accepted' => NotifType.messageRequestAccepted,
      'message_request_rejected' => NotifType.messageRequestRejected,
      'study_group_invite' => NotifType.studyGroupInvite,
      'study_group_invite_accepted' => NotifType.studyGroupInviteAccepted,
      'study_group_invite_declined' => NotifType.studyGroupInviteDeclined,
      'study_group_join_request' => NotifType.studyGroupJoinRequest,
      'study_group_join_approved' => NotifType.studyGroupJoinApproved,
      'study_group_join_rejected' => NotifType.studyGroupJoinRejected,
      'hackathon_started' => NotifType.hackathonStarted,
      'achievement' => NotifType.achievement,
      'learning' => NotifType.learning,
      _ => NotifType.system,
    };
