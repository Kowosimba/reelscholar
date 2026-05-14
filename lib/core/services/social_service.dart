// lib/core/services/social_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reelscholar/core/constants/api_constants.dart';
import 'package:reelscholar/models/social_models.dart';

class SocialService {
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

  // ── GET /users/search?q=&filter= ────────────────────────────────────────
  Future<({List<AppUser> users, int total, int lastPage})> searchUsers({
    required String query,
    String filter = 'all',
    int page = 1,
    int perPage = 20,
  }) async {
    final params = {
      'q': query,
      'filter': filter,
      'page': '$page',
      'per_page': '$perPage',
    };
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/search').replace(queryParameters: params),
      headers: await _headers(),
    );
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    List items;
    int total = 0;
    int lastPage = 1;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = data['data'] as List? ?? [];
      final meta = body['meta'] as Map<String, dynamic>? ?? {};
      total = meta['total'] as int? ?? 0;
      lastPage = meta['last_page'] as int? ?? 1;
    } else {
      items = [];
    }
    return (
      users: items
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .toList(),
      total: total,
      lastPage: lastPage,
    );
  }

  // ── GET /users/{userId} ─────────────────────────────────────────────────
  Future<AppUser> getUser(String userId) async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return AppUser.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── GET /users/suggestions ───────────────────────────────────────────────
  Future<List<AppUser>> getSuggestions() async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/suggestions'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as List)
        .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  // ── POST /users/{userId}/follow (toggle) ─────────────────────────────────
  Future<({bool isFollowing, int followersCount})> toggleFollow(
      String userId) async {
    final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/follow'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return (
      isFollowing: data['is_following'] as bool,
      followersCount:
          int.tryParse(data['followers_count']?.toString() ?? '0') ?? 0,
    );
  }

  // ── POST /users/{userId}/block ───────────────────────────────────────────
  Future<void> blockUser(String userId) async {
    final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/block'), headers: await _headers());
    _ok(res);
  }

  // ── DELETE /users/{userId}/block ─────────────────────────────────────────
  Future<void> unblockUser(String userId) async {
    final res = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/block'), headers: await _headers());
    _ok(res);
  }

  // ── GET /users/blocked ───────────────────────────────────────────────────
  Future<List<AppUser>> getBlockedUsers({int page = 1}) async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/blocked?page=$page'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) {
      return data
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── GET /users/{userId}/followers ─────────────────────────────────────────
  Future<List<AppUser>> getUserFollowers(String userId, {int page = 1}) async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/followers?page=$page'),
        headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) {
      return data
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── GET /users/{userId}/following ─────────────────────────────────────────
  Future<List<AppUser>> getUserFollowing(String userId, {int page = 1}) async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/following?page=$page'),
        headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) {
      return data
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── GET /social/followers (my followers) ─────────────────────────────────
  Future<List<AppUser>> getMyFollowers({int page = 1}) async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/social/followers?page=$page'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) {
      return data
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── GET /social/following (my following) ─────────────────────────────────
  Future<List<AppUser>> getMyFollowing({int page = 1}) async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/social/following?page=$page'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) {
      return data
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    return [];
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
