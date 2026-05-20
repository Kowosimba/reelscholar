import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reelscholar/models/messaging_models.dart';

import '../constants/api_constants.dart';

/// Messaging API — OpenAPI tags `Conversation`, `MessageRequest`.
class MessagingService {
  static const String _tokenKey = 'auth_token';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _assertOk(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = body['message'] as String?;
      throw Exception(msg ?? 'Request failed (${res.statusCode})');
    } on FormatException {
      throw Exception('Request failed (${res.statusCode})');
    }
  }

  /// GET /conversations/{conversationId}
  Future<Conversation> getConversation(String conversationId) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/conversations/$conversationId'),
      headers: await _headers(),
    );
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Conversation.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// GET /conversations
  Future<List<Conversation>> getConversations({
    String? type,
    int perPage = 30,
    int page = 1,
  }) async {
    final params = <String, String>{'per_page': '$perPage', 'page': '$page'};
    if (type != null && type != 'all') params['type'] = type;
    final uri = Uri.parse('${ApiConstants.baseUrl}/conversations')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as List? ?? [];
    return data
        .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// GET /conversations/my-chats
  Future<List<Conversation>> getMyChats() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/conversations/my-chats'),
      headers: await _headers(),
    );
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as List? ?? [];
    return data
        .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// GET /conversations/{id}/messages — returns newest-first list + pagination.
  Future<({List<ConvMessage> items, int currentPage, int lastPage})>
      getMessages(
    String conversationId, {
    int perPage = 50,
    int page = 1,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/conversations/$conversationId/messages',
    ).replace(queryParameters: {'per_page': '$perPage', 'page': '$page'});
    final res = await http.get(uri, headers: await _headers());
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = body['data'];
    List<dynamic> list = [];
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      list = raw['data'] as List? ?? [];
    }
    final items = list
        .map((m) => ConvMessage.fromJson(m as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final meta = body['meta'] as Map<String, dynamic>?;
    final current =
        int.tryParse(meta?['current_page']?.toString() ?? '$page') ?? page;
    final last =
        int.tryParse(meta?['last_page']?.toString() ?? '$current') ?? current;
    return (items: items, currentPage: current, lastPage: last);
  }

  /// POST /conversations/{id}/messages/text
  Future<ConvMessage> sendTextMessage(
    String conversationId,
    String bodyText, {
    String? replyToMessageId,
  }) async {
    final payload = <String, dynamic>{'body': bodyText};
    if (replyToMessageId != null) {
      payload['reply_to_message_id'] = replyToMessageId;
    }
    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/conversations/$conversationId/messages/text',
      ),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    _assertOk(res);
    final rb = jsonDecode(res.body) as Map<String, dynamic>;
    return ConvMessage.fromJson(rb['data'] as Map<String, dynamic>);
  }

  /// POST /conversations/{id}/messages/media
  Future<ConvMessage> sendMediaMessage(
    String conversationId,
    List<File> files, {
    String? caption,
    String? replyToMessageId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConstants.baseUrl}/conversations/$conversationId/messages/media',
      ),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    if (caption != null && caption.isNotEmpty) {
      request.fields['body'] = caption;
    }
    if (replyToMessageId != null) {
      request.fields['reply_to_message_id'] = replyToMessageId;
    }
    for (final f in files) {
      request.files.add(
        await http.MultipartFile.fromPath('attachments[]', f.path),
      );
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _assertOk(res);
    final rb = jsonDecode(res.body) as Map<String, dynamic>;
    return ConvMessage.fromJson(rb['data'] as Map<String, dynamic>);
  }

  /// POST /conversations/{id}/read
  Future<void> markAsRead(String conversationId) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/conversations/$conversationId/read'),
      headers: await _headers(),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;
  }

  /// POST /conversations/{id}/mute
  Future<void> toggleMute(String conversationId,
      {required bool mute, DateTime? mutedUntil}) async {
    final payload = <String, dynamic>{'is_muted': mute};
    if (mutedUntil != null) {
      payload['muted_until'] = mutedUntil.toIso8601String();
    }
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/conversations/$conversationId/mute'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    _assertOk(res);
  }

  /// POST /messages/{id}/react
  Future<({bool added, Map<String, dynamic> reactions})> reactToMessage(
    String messageId,
    String emoji,
  ) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/messages/$messageId/react'),
      headers: await _headers(),
      body: jsonEncode({'emoji': emoji}),
    );
    _assertOk(res);
    final rb = jsonDecode(res.body) as Map<String, dynamic>;
    final data = rb['data'] as Map<String, dynamic>;
    return (
      added: data['added'] as bool? ?? true,
      reactions: data['reactions'] as Map<String, dynamic>? ?? {},
    );
  }

  /// DELETE /messages/{id}
  Future<void> deleteMessage(String messageId) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/messages/$messageId'),
      headers: await _headers(),
    );
    _assertOk(res);
  }

  /// POST /conversations/group
  Future<Conversation> createGroupConversation({
    required String name,
    required List<String> participantIds,
    String? description,
    bool anyoneCanMessage = true,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'participant_ids': participantIds,
      if (description != null && description.isNotEmpty)
        'description': description,
      'anyone_can_message': anyoneCanMessage,
    };
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/conversations/group'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Conversation.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// GET /study-groups/{groupId}/messages  (cursor-based)
  Future<({List<ConvMessage> items, String? nextCursor, bool hasMore})>
      getStudyGroupMessages(
    String groupId, {
    String? cursor,
    int perPage = 50,
  }) async {
    final params = <String, String>{'per_page': '$perPage'};
    if (cursor != null) params['cursor'] = cursor;
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/study-groups/$groupId/messages')
            .replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    final meta = body['meta'] as Map<String, dynamic>? ?? {};
    final items = list
        .map((m) => ConvMessage.fromJson(m as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final nextCursor = meta['next_cursor']?.toString();
    final hasMore =
        meta['has_more']?.toString() == 'true' || meta['has_more'] == true;
    return (items: items, nextCursor: nextCursor, hasMore: hasMore);
  }

  /// POST /study-groups/{groupId}/messages/text
  Future<ConvMessage> sendStudyGroupTextMessage(
    String groupId,
    String bodyText, {
    String? replyToMessageId,
  }) async {
    final payload = <String, dynamic>{'body': bodyText};
    if (replyToMessageId != null) {
      payload['reply_to_message_id'] = replyToMessageId;
    }
    final res = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/study-groups/$groupId/messages/text'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    _assertOk(res);
    final rb = jsonDecode(res.body) as Map<String, dynamic>;
    return ConvMessage.fromJson(rb['data'] as Map<String, dynamic>);
  }

  /// GET /conversations/study-groups
  Future<List<Conversation>> getStudyGroupConversations({
    int page = 1,
    int perPage = 30,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/conversations/study-groups',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final res = await http.get(uri, headers: await _headers());
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    final List<dynamic> list =
        data is List ? data : (data as Map<String, dynamic>?)?['data'] as List? ?? [];
    return list
        .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> startTyping(String conversationId) async {
    await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/conversations/$conversationId/typing/start',
      ),
      headers: await _headers(),
    );
  }

  Future<void> stopTyping(String conversationId) async {
    await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/conversations/$conversationId/typing/stop',
      ),
      headers: await _headers(),
    );
  }

  /// GET /message-requests
  Future<List<MessageRequest>> getMessageRequests({
    String status = 'pending',
    int perPage = 20,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/message-requests').replace(
      queryParameters: {'status': status, 'per_page': '$perPage'},
    );
    final res = await http.get(uri, headers: await _headers());
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as List? ?? [];
    return data
        .map((r) => MessageRequest.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// POST /message-requests
  Future<Map<String, dynamic>> sendMessageRequest({
    required String receiverId,
    required String initialMessage,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/message-requests'),
      headers: await _headers(),
      body: jsonEncode({
        'receiver_id': receiverId,
        'initial_message': initialMessage,
      }),
    );
    _assertOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// POST /message-requests/{id}/accept
  Future<Conversation> acceptRequest(String requestId) async {
    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/message-requests/$requestId/accept',
      ),
      headers: await _headers(),
    );
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return Conversation.fromJson(
      data['conversation'] as Map<String, dynamic>,
    );
  }

  /// POST /message-requests/{id}/reject
  Future<void> rejectRequest(String requestId) async {
    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/message-requests/$requestId/reject',
      ),
      headers: await _headers(),
    );
    _assertOk(res);
  }
}
