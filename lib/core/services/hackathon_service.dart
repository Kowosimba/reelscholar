// lib/core/services/hackathon_service.dart

import 'dart:convert';
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
  Future<({List<Hackathon> items, int total, int lastPage})>
      listHackathons({int page = 1}) async {
    final headers = await _getHeaders();
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/hackathons?page=$page'), 
        headers: headers);
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
      meta = body['meta'] as Map<String, dynamic>? ??
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
        headers: headers);
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Hackathon.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── GET /hackathons/{id}/leaderboard ─────────────────────────────────────
  Future<List<HackLeaderboardEntry>> getLeaderboard(String id) async {
    final headers = await _getHeaders();
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/hackathons/$id/leaderboard'), 
        headers: headers);
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as List)
        .map((e) =>
            HackLeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── POST /hackathons/{id}/teams ───────────────────────────────────────────
  Future<({String teamId, String name, String inviteCode})>
      createTeam(String hackId, String name) async {
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
        headers: headers);
    _ok(res);
  }

  // ── GET /hackathons/{id}/teams/open ───────────────────────────────────────
  Future<List<OpenTeam>> getOpenTeams(String hackId) async {
    final headers = await _getHeaders();
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/teams/open'),
        headers: headers);
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as List)
        .map((t) => OpenTeam.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  // ── POST /hackathons/{id}/submission (draft save) ─────────────────────────
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

  // ── POST /hackathons/{id}/submission/finalise ────────────────────────────
  Future<void> finaliseSubmission(String hackId) async {
    final headers = await _getHeaders();
    final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/submission/finalise'),
        headers: headers);
    _ok(res);
  }

  // ── GET /hackathons/{id}/submissions ─────────────────────────────────────
  Future<List<HackSubmission>> getSubmissions(String hackId) async {
    final headers = await _getHeaders();
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/submissions'),
        headers: headers);
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as List)
        .map((s) =>
            HackSubmission.fromJson(s as Map<String, dynamic>))
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

  // ── GET /hackathons/{id}/vote/status ─────────────────────────────────────
  Future<VoteStatus> getVoteStatus(String hackId) async {
    final headers = await _getHeaders();
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/vote/status'),
        headers: headers);
    _ok(res);
    final data =
        (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return VoteStatus.fromJson(data);
  }

  // ── GET /hackathons/{id}/discussion ──────────────────────────────────────
  Future<({List<DiscussionComment> comments, int total})>
      getDiscussion(String hackId, {int page = 1}) async {
    final headers = await _getHeaders();
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/discussion?page=$page'),
        headers: headers);
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
      meta = body['meta'] as Map<String, dynamic>? ??
          rawData['meta'] as Map<String, dynamic>? ??
          {};
    } else {
      items = [];
      meta = {};
    }
    return (
      comments: items
          .map((c) =>
              DiscussionComment.fromJson(c as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int? ?? 0,
    );
  }

  // ── POST /hackathons/{id}/discussion ─────────────────────────────────────
  Future<DiscussionComment> postComment(
      String hackId, String body) async {
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
      String hackId, String commentId, String body) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/hackathons/$hackId/discussion/$commentId/reply'),
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
        headers: headers);
  }

  // ── DELETE /hackathon-comments/{id} ──────────────────────────────────────
  Future<void> deleteComment(String commentId) async {
    final headers = await _getHeaders();
    final res = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/hackathon-comments/$commentId'),
        headers: headers);
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
      String hackId, String teamId, String body) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/mentor/chat/$teamId'),
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
      String hackId, String teamId) async {
    final headers = await _getHeaders();
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/hackathons/$hackId/mentor/chat/$teamId'),
        headers: headers);
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

  void _ok(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String? msg;
    try {
      msg = (jsonDecode(res.body) as Map)['message'] as String?;
    } catch (_) {}
    throw Exception(msg ?? 'Request failed (${res.statusCode})');
  }
}
