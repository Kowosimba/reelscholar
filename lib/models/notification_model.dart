enum NotifType { like, comment, follow, achievement, learning, system }

class AppNotification {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: _typeFromString(json['type']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
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
      'like' => NotifType.like,
      'comment' => NotifType.comment,
      'follow' => NotifType.follow,
      'achievement' => NotifType.achievement,
      'learning' => NotifType.learning,
      _ => NotifType.system,
    };
