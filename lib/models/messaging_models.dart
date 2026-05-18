import 'dart:convert';

bool _parseApiBool(dynamic v) {
  if (v is bool) return v;
  if (v is String) return v == 'true' || v == '1';
  if (v is int) return v == 1;
  return false;
}

class MessageSender {
  final String uid;
  final String name;
  final String? profilePic;

  const MessageSender({
    required this.uid,
    required this.name,
    this.profilePic,
  });

  factory MessageSender.fromJson(Map<String, dynamic> j) => MessageSender(
        uid: j['uid']?.toString() ?? j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? 'Unknown',
        profilePic: j['profile_pic'] as String? ?? j['profile_pic_url'] as String?,
      );
}

class ReplyContext {
  final String messageId;
  final String body;
  final String senderName;

  const ReplyContext({
    required this.messageId,
    required this.body,
    required this.senderName,
  });

  factory ReplyContext.fromJson(Map<String, dynamic> j) => ReplyContext(
        messageId: j['message_id']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        senderName: j['sender_name']?.toString() ?? '',
      );
}

class MessageAttachment {
  final String url;
  final String? type;
  final String? name;

  const MessageAttachment({required this.url, this.type, this.name});

  factory MessageAttachment.fromJson(Map<String, dynamic> j) =>
      MessageAttachment(
        url: j['url']?.toString() ?? '',
        type: j['type'] as String?,
        name: j['name'] as String?,
      );

  bool get isImage =>
      type == 'image' ||
      _looksLikeImage(url);

  bool _looksLikeImage(String u) =>
      u.endsWith('.jpg') ||
      u.endsWith('.jpeg') ||
      u.endsWith('.png') ||
      u.endsWith('.gif') ||
      u.endsWith('.webp');
}

/// Direct / group chat message (distinct from tutor [ChatMessage] in tutor_models).
class ConvMessage {
  final String id;
  final String conversationId;
  final MessageSender sender;
  final String body;
  final String type;
  final List<MessageAttachment> attachments;
  final String? systemMessageType;
  final ReplyContext? replyTo;
  final Map<String, List<String>> reactions;
  final bool isRead;
  final int readByCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPending;
  final bool isFailed;

  const ConvMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.body,
    required this.type,
    required this.attachments,
    this.systemMessageType,
    this.replyTo,
    required this.reactions,
    required this.isRead,
    required this.readByCount,
    required this.createdAt,
    required this.updatedAt,
    this.isPending = false,
    this.isFailed = false,
  });

  factory ConvMessage.fromJson(Map<String, dynamic> j) {
    final atts = _parseAttachments(j['attachments']);
    final rxns = _parseReactions(j['reactions']);

    return ConvMessage(
      id: j['id']?.toString() ?? '',
      conversationId: j['conversation_id']?.toString() ?? '',
      sender: MessageSender.fromJson(
        Map<String, dynamic>.from(j['sender'] as Map? ?? {}),
      ),
      body: j['body']?.toString() ?? '',
      type: j['type']?.toString() ?? 'text',
      attachments: atts,
      systemMessageType: j['system_message_type'] as String?,
      replyTo: j['reply_to'] != null && j['reply_to'] is Map
          ? ReplyContext.fromJson(
              Map<String, dynamic>.from(j['reply_to'] as Map),
            )
          : null,
      reactions: rxns,
      isRead: _parseApiBool(j['is_read']),
      readByCount: int.tryParse(j['read_by_count']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  ConvMessage copyWith({
    bool? isPending,
    bool? isFailed,
    Map<String, List<String>>? reactions,
    String? id,
  }) =>
      ConvMessage(
        id: id ?? this.id,
        conversationId: conversationId,
        sender: sender,
        body: body,
        type: type,
        attachments: attachments,
        systemMessageType: systemMessageType,
        replyTo: replyTo,
        reactions: reactions ?? this.reactions,
        isRead: isRead,
        readByCount: readByCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isPending: isPending ?? this.isPending,
        isFailed: isFailed ?? this.isFailed,
      );

  bool get isSystem => type == 'system';
  bool get isMedia => type == 'media' || attachments.isNotEmpty;

  static List<MessageAttachment> _parseAttachments(dynamic raw) {
    if (raw == null || raw == 'null') return [];
    if (raw is List) {
      return raw
          .map((e) => MessageAttachment.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is List) {
          return d
              .map((e) => MessageAttachment.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList();
        }
      } catch (_) {}
    }
    return [];
  }

  static Map<String, List<String>> _parseReactions(dynamic raw) {
    if (raw == null || raw == 'null') return {};
    if (raw is Map) {
      return raw.map((k, v) {
        if (v is List) {
          return MapEntry(
            k.toString(),
            v.map((e) => e.toString()).toList(),
          );
        }
        return MapEntry(k.toString(), [v.toString()]);
      });
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) return _parseReactions(d);
      } catch (_) {}
    }
    return {};
  }
}

class ConversationParticipant {
  final String id;
  final String name;
  final String? profilePic;
  final String? role;

  const ConversationParticipant({
    required this.id,
    required this.name,
    this.profilePic,
    this.role,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> j) =>
      ConversationParticipant(
        id: (j['id'] ?? j['uid'] ?? '').toString(),
        name: j['full_name'] as String? ??
            j['name'] as String? ??
            'Unknown',
        profilePic: j['profile_picture'] as String? ??
            j['profile_pic'] as String? ??
            j['profile_pic_url'] as String?,
        role: j['role'] as String?,
      );

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class Conversation {
  final String id;
  final String type;
  final String? name;
  final String? description;
  final String? avatarUrl;
  final String? studyGroupId;
  final ConversationParticipant? otherUser;
  final ConversationParticipant? creator;
  final List<ConversationParticipant> participants;
  final int participantsCount;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final String role;
  final bool isMuted;
  final DateTime? mutedUntil;
  final int unreadCount;
  final DateTime? lastReadAt;
  final bool anyoneCanMessage;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.type,
    this.name,
    this.description,
    this.avatarUrl,
    this.studyGroupId,
    this.otherUser,
    this.creator,
    required this.participants,
    required this.participantsCount,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.role,
    required this.isMuted,
    this.mutedUntil,
    required this.unreadCount,
    this.lastReadAt,
    required this.anyoneCanMessage,
    required this.createdAt,
  });

  bool get isDirect => type == 'direct';
  bool get isGroup => type == 'group';

  String get displayName {
    if (isDirect) return otherUser?.name ?? 'Unknown';
    return name ?? 'Group Chat';
  }

  String get displayInitials {
    if (isDirect) return otherUser?.initials ?? '?';
    final n = displayName;
    final parts = n.split(' ');
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  factory Conversation.fromJson(Map<String, dynamic> j) {
    ConversationParticipant? otherUser;
    if (j['other_user'] != null && j['other_user'] is Map) {
      otherUser = ConversationParticipant.fromJson(
        Map<String, dynamic>.from(j['other_user'] as Map),
      );
    }
    ConversationParticipant? creator;
    if (j['creator'] != null && j['creator'] is Map) {
      creator = ConversationParticipant.fromJson(
        Map<String, dynamic>.from(j['creator'] as Map),
      );
    }
    final rawParts = j['participants'] as List? ?? [];
    final participants = rawParts
        .map((p) => ConversationParticipant.fromJson(
              Map<String, dynamic>.from(p as Map),
            ))
        .toList();
    final rawType = (j['type'] ??
            j['conversation_type'] ??
            j['chat_type'] ??
            '')
        .toString()
        .toLowerCase();
    final inferredGroup = rawType == 'group' ||
        rawType == 'study_group' ||
        rawType == 'study-group' ||
        j['study_group_id'] != null ||
        j['group_id'] != null ||
        j['study_group'] is Map<String, dynamic>;
    final resolvedType = inferredGroup
        ? 'group'
        : (rawType == 'direct' ||
                rawType == 'dm' ||
                rawType == 'private' ||
                otherUser != null)
            ? 'direct'
            : participants.length > 2
                ? 'group'
                : 'direct';

    final sgId = j['study_group_id']?.toString() ??
        j['group_id']?.toString() ??
        (j['study_group'] is Map<String, dynamic>
            ? (j['study_group'] as Map<String, dynamic>)['id']?.toString()
            : null);

    return Conversation(
      id: j['id']?.toString() ?? '',
      type: resolvedType,
      name: j['name'] as String?,
      description: j['description'] as String?,
      avatarUrl: j['avatar_url'] as String?,
      studyGroupId: sgId,
      otherUser: otherUser,
      creator: creator,
      participants: participants,
      participantsCount:
          int.tryParse(j['participants_count']?.toString() ?? '0') ?? 0,
      lastMessagePreview: j['last_message_preview'] as String?,
      lastMessageAt:
          DateTime.tryParse(j['last_message_at']?.toString() ?? ''),
      role: j['role']?.toString() ?? 'member',
      isMuted: _parseApiBool(j['is_muted']),
      mutedUntil:
          DateTime.tryParse(j['muted_until']?.toString() ?? ''),
      unreadCount:
          int.tryParse(j['unread_count']?.toString() ?? '0') ?? 0,
      lastReadAt:
          DateTime.tryParse(j['last_read_at']?.toString() ?? ''),
      anyoneCanMessage: j['anyone_can_message'] == true ||
          j['anyone_can_message'] == 'true',
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Conversation copyWith({
    int? unreadCount,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    bool? isMuted,
  }) =>
      Conversation(
        id: id,
        type: type,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        studyGroupId: studyGroupId,
        otherUser: otherUser,
        creator: creator,
        participants: participants,
        participantsCount: participantsCount,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        role: role,
        isMuted: isMuted ?? this.isMuted,
        mutedUntil: mutedUntil,
        unreadCount: unreadCount ?? this.unreadCount,
        lastReadAt: lastReadAt,
        anyoneCanMessage: anyoneCanMessage,
        createdAt: createdAt,
      );
}

class MessageRequest {
  final String id;
  final ConversationParticipant? sender;
  final ConversationParticipant? receiver;
  final String initialMessage;
  final String status;
  final String? conversationId;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const MessageRequest({
    required this.id,
    this.sender,
    this.receiver,
    required this.initialMessage,
    required this.status,
    this.conversationId,
    required this.createdAt,
    this.respondedAt,
  });

  bool get isPending => status == 'pending';

  factory MessageRequest.fromJson(Map<String, dynamic> j) {
    ConversationParticipant? sender;
    if (j['sender'] != null && j['sender'] is Map) {
      sender = ConversationParticipant.fromJson(
        Map<String, dynamic>.from(j['sender'] as Map),
      );
    }
    ConversationParticipant? receiver;
    if (j['receiver'] != null && j['receiver'] is Map) {
      receiver = ConversationParticipant.fromJson(
        Map<String, dynamic>.from(j['receiver'] as Map),
      );
    }
    return MessageRequest(
      id: j['id']?.toString() ?? '',
      sender: sender,
      receiver: receiver,
      initialMessage: j['initial_message']?.toString() ?? '',
      status: j['status']?.toString() ?? 'pending',
      conversationId: j['conversation_id'] as String?,
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      respondedAt:
          DateTime.tryParse(j['responded_at']?.toString() ?? ''),
    );
  }
}
