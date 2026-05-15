// lib/features/study_groups/services/study_group_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'package:reelscholar/models/study_group_models.dart';

class StudyGroupService {
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

  // ── GET /study-groups ─────────────────────────────────────────────────────
  Future<({List<StudyGroup> groups, int total, int lastPage})>
      browseGroups({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/study-groups').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final items = _extractList(body['data']);
    final meta = _extractMeta(body);
    return (
      groups: items
          .map((g) => StudyGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int? ?? 0,
      lastPage: meta['last_page'] as int? ?? 1,
    );
  }

  // ── POST /study-groups ────────────────────────────────────────────────────
  Future<StudyGroup> createGroup({
    required String name,
    String? description,
    String? subject,
    bool isPublic = true,
    bool adminOnlyMessaging = false,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/study-groups'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        'is_public': isPublic,
        'admin_only_messaging': adminOnlyMessaging,
      }),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return StudyGroup.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── GET /study-groups/my ─────────────────────────────────────────────────
  Future<List<StudyGroup>> getMyGroups() async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/study-groups/my'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return _extractList(body['data'])
        .map((g) => StudyGroup.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  // ── GET /study-groups/{id} ────────────────────────────────────────────────
  Future<StudyGroup> getGroup(String id) async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/study-groups/$id'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return StudyGroup.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── PATCH /study-groups/{id} ──────────────────────────────────────────────
  Future<StudyGroup> updateGroup(
    String id, {
    String? name,
    String? description,
    String? subject,
    bool? isPublic,
    bool? adminOnlyMessaging,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (description != null) payload['description'] = description;
    if (subject != null) payload['subject'] = subject;
    if (isPublic != null) payload['is_public'] = isPublic;
    if (adminOnlyMessaging != null) {
      payload['admin_only_messaging'] = adminOnlyMessaging;
    }
    final res = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/study-groups/$id'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return StudyGroup.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── DELETE /study-groups/{id} ─────────────────────────────────────────────
  Future<void> deleteGroup(String id) async {
    final res = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/study-groups/$id'), headers: await _headers());
    _ok(res);
  }

  // ── POST /study-groups/{id}/leave ─────────────────────────────────────────
  Future<void> leaveGroup(String id) async {
    final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/study-groups/$id/leave'), headers: await _headers());
    _ok(res);
  }

  // ── GET /study-groups/{id}/members ───────────────────────────────────────
  Future<List<GroupMember>> getMembers(String groupId) async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/study-groups/$groupId/members'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) {
      return data
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── POST /study-groups/{id}/members ──────────────────────────────────────
  Future<void> addMember(String groupId, String userId) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/study-groups/$groupId/members'),
      headers: await _headers(),
      body: jsonEncode({'user_id': userId}),
    );
    _ok(res);
  }

  // ── POST /study-groups/{id}/members/{userId}/promote ─────────────────────
  Future<void> promoteMember(String groupId, String userId) async {
    final res = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/study-groups/$groupId/members/$userId/promote'),
      headers: await _headers(),
    );
    _ok(res);
  }

  // ── POST /study-groups/{id}/members/{userId}/demote ──────────────────────
  Future<void> demoteMember(String groupId, String userId) async {
    final res = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/study-groups/$groupId/members/$userId/demote'),
      headers: await _headers(),
    );
    _ok(res);
  }

  // ── DELETE /study-groups/{id}/members/{userId} ────────────────────────────
  Future<void> removeMember(String groupId, String userId) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/study-groups/$groupId/members/$userId'),
      headers: await _headers(),
    );
    _ok(res);
  }

  // ── GET /study-groups/{id}/invites ────────────────────────────────────────
  Future<List<GroupInvite>> getGroupInvites(String groupId,
      {String status = 'pending'}) async {
    final res = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}/study-groups/$groupId/invites?status=$status'),
      headers: await _headers(),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) {
      return data
          .map((i) => GroupInvite.fromJson(i as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── POST /study-groups/{id}/invites ──────────────────────────────────────
  Future<GroupInvite> sendInvite(String groupId, String userId) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/study-groups/$groupId/invites'),
      headers: await _headers(),
      body: jsonEncode({'user_id': userId}),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return GroupInvite.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── DELETE /study-groups/{id}/invites/{inviteId} ──────────────────────────
  Future<void> revokeInvite(String groupId, String inviteId) async {
    final res = await http.delete(
      Uri.parse(
          '${ApiConstants.baseUrl}/study-groups/$groupId/invites/$inviteId'),
      headers: await _headers(),
    );
    _ok(res);
  }

  // ── GET /my-invites ───────────────────────────────────────────────────────
  Future<List<GroupInvite>> getMyInvites(
      {String status = 'pending'}) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/my-invites?status=$status'),
      headers: await _headers(),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as List? ?? [])
        .map((i) => GroupInvite.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  // ── POST /invites/{token}/accept ──────────────────────────────────────────
  Future<Map<String, dynamic>> acceptInvite(String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/invites/$token/accept'),
      headers: await _headers(),
    );
    _ok(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── POST /invites/{token}/decline ─────────────────────────────────────────
  Future<void> declineInvite(String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/invites/$token/decline'),
      headers: await _headers(),
    );
    _ok(res);
  }

  // ── GET /study-groups/{id}/join-requests ─────────────────────────────────
  Future<List<JoinRequest>> getJoinRequests(String groupId,
      {String status = 'pending'}) async {
    final res = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}/study-groups/$groupId/join-requests?status=$status'),
      headers: await _headers(),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final items = data['data'] as List? ?? body['data'] as List? ?? [];
    return items
        .map((r) => JoinRequest.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ── POST /study-groups/{id}/join-requests ────────────────────────────────
  Future<void> sendJoinRequest(String groupId) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/study-groups/$groupId/join-requests'),
      headers: await _headers(),
    );
    _ok(res);
  }

  // ── GET /study-groups/{id}/join-requests/pending-count ───────────────────
  Future<int> getPendingRequestCount(String groupId) async {
    final res = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}/study-groups/$groupId/join-requests/pending-count'),
      headers: await _headers(),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>?)?['count'] as int? ?? 0;
  }

  // ── POST /study-groups/{id}/join-requests/{reqId}/approve ────────────────
  Future<void> approveRequest(String groupId, String requestId) async {
    final res = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/study-groups/$groupId/join-requests/$requestId/approve'),
      headers: await _headers(),
    );
    _ok(res);
  }

  // ── POST /study-groups/{id}/join-requests/{reqId}/reject ─────────────────
  Future<void> rejectRequest(String groupId, String requestId) async {
    final res = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/study-groups/$groupId/join-requests/$requestId/reject'),
      headers: await _headers(),
    );
    _ok(res);
  }

  // ── DELETE /study-groups/{id}/join-requests/{reqId} ──────────────────────
  Future<void> cancelJoinRequest(String groupId, String requestId) async {
    final res = await http.delete(
      Uri.parse(
          '${ApiConstants.baseUrl}/study-groups/$groupId/join-requests/$requestId'),
      headers: await _headers(),
    );
    _ok(res);
  }

  void _ok(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String? msg;
    try {
      msg = (jsonDecode(res.body) as Map)['message'] as String?;
    } catch (_) {}
    throw Exception(msg ?? 'Request failed (${res.statusCode})');
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) return nested;
      final items = data['items'];
      if (items is List) return items;
    }
    return [];
  }

  Map<String, dynamic> _extractMeta(Map<String, dynamic> body) {
    final meta = body['meta'];
    if (meta is Map<String, dynamic>) return meta;
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final current = data['meta'];
      if (current is Map<String, dynamic>) return current;
    }
    return {};
  }
}

