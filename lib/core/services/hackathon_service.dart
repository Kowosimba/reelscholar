// lib/core/services/hackathon_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reelscholar/core/constants/api_constants.dart';
import 'package:reelscholar/models/hackathon_models.dart';

class HackathonService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── GET /hackathons ───────────────────────────────────────────────────────
  Future<({List<Hackathon> items, int total, int lastPage})> listHackathons({
    int page = 1,
  }) async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/hackathons?page=$page'),
      headers: headers,
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rawData = body['data'];
    final List items;
    final Map<String, dynamic> meta;
    if (rawData is List) {
      items = rawData;
      meta = body['meta'] as Map<String, dynamic>? ?? {};
    } else if (rawData is Map<String, dynamic>) {
      items = rawData['data'] as List? ?? [];
      meta =
          body['meta'] as Map<String, dynamic>? ??
          rawData['meta'] as Map<String, dynamic>? ??
          {};
    } else {
      items = [];
      meta = {};
    }
    return (
      items: items
          .map((h) => Hackathon.fromJson(h as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int? ?? 0,
      lastPage: meta['last_page'] as int? ?? 1,
    );
  }

  // ── GET /hackathons/{id} ──────────────────────────────────────────────────
  Future<Hackathon> getHackathon(String id) async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$id'),
      headers: headers,
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Hackathon.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── GET /hackathons/{id}/leaderboard ─────────────────────────────────────
  Future<List<HackLeaderboardEntry>> getLeaderboard(String id) async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$id/leaderboard'),
      headers: headers,
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as List)
        .map((e) => HackLeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── POST /hackathons/{id}/teams ───────────────────────────────────────────
  Future<({String teamId, String name, String inviteCode})> createTeam(
    String hackId,
    String name,
  ) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/teams'),
      headers: headers,
      body: jsonEncode({'name': name}),
    );
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return (
      teamId: data['team_id'] as String,
      name: data['name'] as String,
      inviteCode: data['invite_code'] as String,
    );
  }

  // ── POST /hackathons/{id}/teams/join ─────────────────────────────────────
  Future<HackTeam> joinTeam(String hackId, String inviteCode) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/teams/join'),
      headers: headers,
      body: jsonEncode({'invite_code': inviteCode}),
    );
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return HackTeam.fromJson(data);
  }

  // ── DELETE /hackathons/{id}/teams/leave ───────────────────────────────────
  Future<void> leaveTeam(String hackId) async {
    final headers = await _getHeaders();
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/teams/leave'),
      headers: headers,
    );
    _ok(res);
  }

  // ── GET /hackathons/{id}/teams/open ───────────────────────────────────────
  Future<List<OpenTeam>> getOpenTeams(String hackId) async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/teams/open'),
      headers: headers,
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as List)
        .map((t) => OpenTeam.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  // ── PATCH /hackathons/{id}/teams/progress ─────────────────────────────────
  Future<void> updateProgress(
    String hackId, {
    required String step,
    required int percentage,
    String? notes,
  }) async {
    final headers = await _getHeaders();
    final res = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/teams/progress'),
      headers: headers,
      body: jsonEncode({
        'step': step,
        'percentage': percentage,
        'notes': ?notes,
      }),
    );
    _ok(res);
  }

  // ── POST /hackathons/{id}/submission ──────────────────────────────────────
  Future<HackSubmission> saveSubmission(
    String hackId, {
    required String projectName,
    required String description,
    String? repoUrl,
    String? demoUrl,
    String? videoUrl,
    List<String>? additionalLinks,
  }) async {
    final headers = await _getHeaders();
    final payload = <String, dynamic>{
      'project_name': projectName,
      'description': description,
      if (repoUrl != null && repoUrl.isNotEmpty) 'repo_url': repoUrl,
      if (demoUrl != null && demoUrl.isNotEmpty) 'demo_url': demoUrl,
      if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
      if (additionalLinks != null && additionalLinks.isNotEmpty)
        'additional_links': additionalLinks,
    };
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/submission'),
      headers: headers,
      body: jsonEncode(payload),
    );
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return HackSubmission.fromJson(data);
  }

  // ── POST /hackathons/{id}/submission/finalise ─────────────────────────────
  Future<void> finaliseSubmission(String hackId) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/submission/finalise',
      ),
      headers: headers,
    );
    _ok(res);
  }

  // ── GET /hackathons/{id}/submissions ──────────────────────────────────────
  Future<List<HackSubmission>> getSubmissions(String hackId) async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/submissions'),
      headers: headers,
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as List)
        .map((s) => HackSubmission.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  // ── POST /hackathons/{id}/vote ────────────────────────────────────────────
  Future<void> castVote(String hackId, String teamId) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/vote'),
      headers: headers,
      body: jsonEncode({'team_id': teamId}),
    );
    _ok(res);
  }

  // ── GET /hackathons/{id}/vote/status ──────────────────────────────────────
  Future<VoteStatus> getVoteStatus(String hackId) async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/vote/status'),
      headers: headers,
    );
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return VoteStatus.fromJson(data);
  }

  // ── GET /hackathons/{id}/discussion ──────────────────────────────────────
  Future<({List<DiscussionComment> comments, int total})> getDiscussion(
    String hackId, {
    int page = 1,
  }) async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/discussion?page=$page',
      ),
      headers: headers,
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rawData = body['data'];
    final List items;
    final Map<String, dynamic> meta;
    if (rawData is List) {
      items = rawData;
      meta = body['meta'] as Map<String, dynamic>? ?? {};
    } else if (rawData is Map<String, dynamic>) {
      items = rawData['data'] as List? ?? [];
      meta =
          body['meta'] as Map<String, dynamic>? ??
          rawData['meta'] as Map<String, dynamic>? ??
          {};
    } else {
      items = [];
      meta = {};
    }
    return (
      comments: items
          .map((c) => DiscussionComment.fromJson(c as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int? ?? 0,
    );
  }

  // ── POST /hackathons/{id}/discussion ─────────────────────────────────────
  Future<DiscussionComment> postComment(String hackId, String body) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/discussion'),
      headers: headers,
      body: jsonEncode({'body': body}),
    );
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return DiscussionComment.fromJson(data);
  }

  // ── POST /hackathons/{id}/discussion/{comment}/reply ─────────────────────
  Future<DiscussionComment> replyToComment(
    String hackId,
    String commentId,
    String body,
  ) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/discussion/$commentId/reply',
      ),
      headers: headers,
      body: jsonEncode({'body': body}),
    );
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return DiscussionComment.fromJson(data);
  }

  // ── POST /hackathon-comments/{id}/like ────────────────────────────────────
  Future<void> likeComment(String commentId) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/hackathon-comments/$commentId/like'),
      headers: headers,
    );
  }

  // ── DELETE /hackathon-comments/{id} ──────────────────────────────────────
  Future<void> deleteComment(String commentId) async {
    final headers = await _getHeaders();
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/hackathon-comments/$commentId'),
      headers: headers,
    );
    _ok(res);
  }

  // ── POST /hackathons/{id}/mentor/request ──────────────────────────────────
  Future<void> requestMentor(String hackId, int mentorId) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/mentor/request'),
      headers: headers,
      body: jsonEncode({'mentor_id': mentorId}),
    );
    _ok(res);
  }

  // ── POST /hackathons/{id}/mentor/chat/{teamId} ────────────────────────────
  Future<MentorMessage> sendMentorMessage(
    String hackId,
    String teamId,
    String body,
  ) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/mentor/chat/$teamId',
      ),
      headers: headers,
      body: jsonEncode({'body': body}),
    );
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return MentorMessage.fromJson(data);
  }

  // ── GET /hackathons/{id}/mentor/chat/{teamId} ─────────────────────────────
  Future<List<MentorMessage>> getMentorChat(
    String hackId,
    String teamId,
  ) async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/mentor/chat/$teamId',
      ),
      headers: headers,
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) {
      return data
          .map((m) => MentorMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TEAM CHAT ENDPOINTS
  // NOTE: team chat endpoints are live on the backend (confirmed).
  // ── GET /hackathons/{hack}/teams/{team}/chat ──────────────────────────────

  Future<({List<HackTeamMessage> items, bool hasMore, int nextPage})>
  getTeamChat(String hackId, String teamId, {int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/hackathons/$hackId/teams/$teamId/chat',
    ).replace(queryParameters: {'per_page': '50', 'page': '$page'});
    final res = await http.get(uri, headers: await _getHeaders());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rawData = body['data'];
    final List list;
    final Map<String, dynamic> meta;
    if (rawData is Map<String, dynamic>) {
      list = rawData['data'] as List? ?? [];
      meta = body['meta'] as Map<String, dynamic>? ??
          rawData['meta'] as Map<String, dynamic>? ?? {};
    } else {
      list = rawData is List ? rawData : [];
      meta = body['meta'] as Map<String, dynamic>? ?? {};
    }
    final currentPage = int.tryParse(meta['current_page']?.toString() ?? '') ?? page;
    final lastPage = int.tryParse(meta['last_page']?.toString() ?? '') ?? 1;
    final items = list
        .map((m) => HackTeamMessage.fromJson(m as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return (
      items: items,
      hasMore: currentPage < lastPage,
      nextPage: currentPage + 1,
    );
  }

  // ── POST /hackathons/{hack}/teams/{team}/chat ─────────────────────────────
  Future<HackTeamMessage> sendTeamChatText(
    String hackId,
    String teamId,
    String bodyText, {
    String? replyToId,
  }) async {
    final payload = <String, dynamic>{'body': bodyText};
    if (replyToId != null) payload['reply_to_id'] = replyToId;
    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/teams/$teamId/chat',
      ),
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return HackTeamMessage.fromJson(data);
  }

  // ── POST /hackathons/{hack}/teams/{team}/chat/media ───────────────────────
  Future<HackTeamMessage> sendTeamChatMedia(
    String hackId,
    String teamId,
    List<File> files, {
    String? caption,
    String? replyToId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/teams/$teamId/chat/media',
      ),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    if (caption != null && caption.isNotEmpty) request.fields['body'] = caption;
    if (replyToId != null) request.fields['reply_to_id'] = replyToId;
    for (final f in files) {
      request.files.add(
        await http.MultipartFile.fromPath('attachments[]', f.path),
      );
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return HackTeamMessage.fromJson(data);
  }

  // ── POST /hackathons/{hack}/teams/{team}/chat/{msg}/react ─────────────────
  Future<Map<String, List<String>>> reactToTeamChatMessage(
    String hackId,
    String teamId,
    String messageId,
    String emoji,
  ) async {
    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/teams/$teamId/chat/$messageId/react',
      ),
      headers: await _getHeaders(),
      body: jsonEncode({'emoji': emoji}),
    );
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>? ??
        {};
    final raw = data['reactions'];
    if (raw is Map) {
      return raw.map(
        (k, v) => MapEntry(
          k.toString(),
          v is List ? v.map((e) => e.toString()).toList() : [v.toString()],
        ),
      );
    }
    return {};
  }

  // ── DELETE /hackathons/{hack}/teams/{team}/chat/{msg} ─────────────────────
  Future<void> deleteTeamChatMessage(
    String hackId,
    String teamId,
    String messageId,
  ) async {
    final res = await http.delete(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/teams/$teamId/chat/$messageId',
      ),
      headers: await _getHeaders(),
    );
    _ok(res);
  }

  // ── POST .../chat/typing/start ────────────────────────────────────────────
  Future<void> startTeamChatTyping(String hackId, String teamId) async {
    await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/teams/$teamId/chat/typing/start',
      ),
      headers: await _getHeaders(),
    );
  }

  // ── POST .../chat/typing/stop ─────────────────────────────────────────────
  Future<void> stopTeamChatTyping(String hackId, String teamId) async {
    await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/teams/$teamId/chat/typing/stop',
      ),
      headers: await _getHeaders(),
    );
  }

  // ── GET .../chat/typing ───────────────────────────────────────────────────
  Future<List<String>> getTeamChatTypingUsers(
    String hackId,
    String teamId,
  ) async {
    final res = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/hackathons/$hackId/teams/$teamId/chat/typing',
      ),
      headers: await _getHeaders(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) return [];
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  // ─────────────────────────────────────────────────────────────────────────
  void _ok(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String? msg;
    try {
      msg = (jsonDecode(res.body) as Map)['message'] as String?;
    } catch (_) {}
    throw Exception(msg ?? 'Request failed (${res.statusCode})');
  }
}
