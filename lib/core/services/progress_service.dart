// lib/core/services/progress_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reelscholar/core/constants/api_constants.dart';
import 'package:reelscholar/models/progress_models.dart';

class ProgressService {
  static const _tokenKey = 'auth_token';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _ok(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String? msg;
    try {
      msg = (jsonDecode(res.body) as Map)['message'] as String?;
    } catch (_) {}
    throw Exception(msg ?? 'Request failed (${res.statusCode})');
  }

  // ── GET /progress/dashboard ───────────────────────────────────────────────
  Future<ProgressDashboard> getDashboard() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/progress/dashboard'),
      headers: await _headers(),
    );
    _ok(res);
    return ProgressDashboard.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── GET /progress/leaderboard?scope= ─────────────────────────────────────
  Future<LeaderboardData> getLeaderboard({String scope = 'programme'}) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/progress/leaderboard')
          .replace(queryParameters: {'scope': scope}),
      headers: await _headers(),
    );
    _ok(res);
    return LeaderboardData.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── GET /progress/achievements ────────────────────────────────────────────
  Future<List<Achievement>> getAchievements() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/progress/achievements'),
      headers: await _headers(),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) {
      return data
          .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── GET /progress/heatmap ─────────────────────────────────────────────────
  Future<List<HeatmapDay>> getHeatmap() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/progress/heatmap'),
      headers: await _headers(),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final calendar = data['calendar'] as List? ?? [];
    return calendar
        .map((d) => HeatmapDay.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  // ── GET /progress/xp ──────────────────────────────────────────────────────
  Future<({List<XpEntry> items, int totalXp, int currentPage, int lastPage})>
      getXpHistory({int page = 1}) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/progress/xp')
          .replace(queryParameters: {'page': '$page'}),
      headers: await _headers(),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final totalXp = body['total_xp'] as int? ?? 0;
    final meta = body['meta'] as Map<String, dynamic>? ?? {};
    final rawData = body['data'];
    List rawItems = [];
    if (rawData is List) {
      rawItems = rawData;
    } else if (rawData is Map) {
      rawItems = rawData['data'] as List? ?? [];
    }
    return (
      items: rawItems
          .map((x) => XpEntry.fromJson(x as Map<String, dynamic>))
          .toList(),
      totalXp: totalXp,
      currentPage: meta['current_page'] as int? ?? page,
      lastPage: meta['last_page'] as int? ?? 1,
    );
  }

  // ── GET /progress/module/{module} ─────────────────────────────────────────
  Future<ModuleProgressDetail> getModuleProgress(String moduleId) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/progress/module/$moduleId'),
      headers: await _headers(),
    );
    _ok(res);
    return ModuleProgressDetail.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── GET /topics?q= ────────────────────────────────────────────────────────
  Future<List<AppTopic>> getTopics({String? query}) async {
    final params = <String, String>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/topics')
          .replace(queryParameters: params.isEmpty ? null : params),
      headers: await _headers(),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) {
      return data.map((t) => AppTopic.fromJson(t)).toList();
    }
    return [];
  }
}
