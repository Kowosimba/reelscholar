import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reelscholar/models/reel_models.dart';
import '../constants/api_constants.dart';

class ReelService {
  static const String _tokenKey = 'auth_token';

  // ─── Auth header ────────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ─── Response parser ────────────────────────────────────────────────────────
  Map<String, dynamic> _parse(http.Response r) {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = body['message'] as String? ?? 'Error ${r.statusCode}';
    throw Exception(msg);
  }

  List<Reel> _reelList(Map<String, dynamic> body) {
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((e) => Reel.fromJson(e as Map<String, dynamic>)).toList();
  }

  PaginationMeta _meta(Map<String, dynamic> body) =>
      PaginationMeta.fromJson(body['meta'] as Map<String, dynamic>?);

  // ─── GET /reels — personalised feed ────────────────────────────────────────
  Future<({List<Reel> reels, PaginationMeta meta})> getFeed({
    int page = 1,
    int perPage = 15,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/reels',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: await _headers());
    final body = _parse(r);
    return (reels: _reelList(body), meta: _meta(body));
  }

  // ─── GET /reels/for-you ─────────────────────────────────────────────────────
  Future<({List<Reel> reels, PaginationMeta meta})> getForYou({
    int page = 1,
    int perPage = 15,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/reels/for-you',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: await _headers());
    final body = _parse(r);
    return (reels: _reelList(body), meta: _meta(body));
  }

  // ─── GET /reels/trending ────────────────────────────────────────────────────
  Future<({List<Reel> reels, PaginationMeta meta})> getTrending({
    int page = 1,
    int perPage = 15,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/reels/trending',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: await _headers());
    final body = _parse(r);
    return (reels: _reelList(body), meta: _meta(body));
  }

  // ─── GET /reels/search?q= ───────────────────────────────────────────────────
  Future<({List<Reel> reels, PaginationMeta meta})> search(
    String query, {
    int page = 1,
    int perPage = 15,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/reels/search').replace(
      queryParameters: {'q': query, 'page': '$page', 'per_page': '$perPage'},
    );
    final r = await http.get(uri, headers: await _headers());
    final body = _parse(r);
    return (reels: _reelList(body), meta: _meta(body));
  }

  // ─── GET /reels/trending-tags ───────────────────────────────────────────────
  Future<List<Hashtag>> getTrendingTags() async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/reels/trending-tags'),
      headers: await _headers(),
    );
    final body = _parse(r);
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => Hashtag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── GET /reels/{id} ────────────────────────────────────────────────────────
  Future<Reel> getReel(String id) async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/reels/$id'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return Reel.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ─── POST /reels — multipart upload ────────────────────────────────────────
  Future<Reel> uploadReel({
    required XFile video,
    String? caption,
    int? topicId,
    void Function(double progress)? onProgress,
  }) async {
    final token = await _token();
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/reels'));

    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final bytes = await video.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'video',
        bytes,
        filename: video.name.isNotEmpty
            ? video.name
            : (kIsWeb ? 'reel-upload.mp4' : video.path.split('/').last),
      ),
    );
    if (caption != null && caption.isNotEmpty) {
      request.fields['body'] = caption;
    }
    if (topicId != null) {
      request.fields['topic_id'] = '$topicId';
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = _parse(response);
    return Reel.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ─── DELETE /reels/{id} ─────────────────────────────────────────────────────
  Future<void> deleteReel(String id) async {
    final r = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/reels/$id'),
      headers: await _headers(),
    );
    _parse(r);
  }

  // ─── GET /reels/user/{userId} ───────────────────────────────────────────────
  Future<({List<Reel> reels, PaginationMeta meta})> getUserReels(
    String userId, {
    int page = 1,
    int perPage = 15,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/reels/user/$userId',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: await _headers());
    final body = _parse(r);
    return (reels: _reelList(body), meta: _meta(body));
  }

  // ─── GET /reels/bookmarks ───────────────────────────────────────────────────
  Future<({List<Reel> reels, PaginationMeta meta})> getBookmarks({
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/reels/bookmarks',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: await _headers());
    final body = _parse(r);
    return (reels: _reelList(body), meta: _meta(body));
  }

  // ─── POST /reels/{id}/like — toggle ────────────────────────────────────────
  Future<bool> toggleLike(String reelId) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/reels/$reelId/like'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return body['data']?['is_liked'] as bool? ?? false;
  }

  // ─── POST /reels/{id}/bookmark — toggle ────────────────────────────────────
  Future<bool> toggleBookmark(String reelId) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/reels/$reelId/bookmark'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return body['data']?['is_bookmarked'] as bool? ?? false;
  }

  // ─── POST /reels/{id}/view ──────────────────────────────────────────────────
  Future<void> recordView(String reelId, {int? watchSeconds}) async {
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/reels/$reelId/view'),
      headers: await _headers(),
      body: jsonEncode({'watch_seconds': watchSeconds}),
    );
    // Fire-and-forget; don't throw on failure
  }

  // ─── POST /reels/{id}/share ─────────────────────────────────────────────────
  Future<void> recordShare(String reelId) async {
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/reels/$reelId/share'),
      headers: await _headers(),
    );
  }

  // ─── GET /reels/{id}/comments ───────────────────────────────────────────────
  Future<({List<ReelComment> comments, PaginationMeta meta})> getComments(
    String reelId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/reels/$reelId/comments',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    final r = await http.get(uri, headers: await _headers());
    final body = _parse(r);
    final data = body['data'] as List<dynamic>? ?? [];
    final comments = data
        .map((e) => ReelComment.fromJson(e as Map<String, dynamic>))
        .toList();
    return (comments: comments, meta: _meta(body));
  }

  // ─── POST /reels/{id}/comments ──────────────────────────────────────────────
  Future<ReelComment> postComment(String reelId, String body) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/reels/$reelId/comments'),
      headers: await _headers(),
      body: jsonEncode({'body': body}),
    );
    final resp = _parse(r);
    return ReelComment.fromJson(resp['data'] as Map<String, dynamic>);
  }

  // ─── POST /comments/{id}/reply ──────────────────────────────────────────────
  Future<ReelComment> replyToComment(
    String commentId,
    String body, {
    String? replyToUserId,
  }) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/comments/$commentId/reply'),
      headers: await _headers(),
      body: jsonEncode({
        'body': body,
        'reply_to_user_id': replyToUserId,
      }),
    );
    final resp = _parse(r);
    return ReelComment.fromJson(resp['data'] as Map<String, dynamic>);
  }

  // ─── GET /comments/{id}/replies ─────────────────────────────────────────────
  Future<List<ReelComment>> getReplies(String commentId, {int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/comments/$commentId/replies',
    ).replace(queryParameters: {'page': '$page'});
    final r = await http.get(uri, headers: await _headers());
    final body = _parse(r);
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => ReelComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── POST /comments/{id}/like — toggle ──────────────────────────────────────
  Future<void> toggleCommentLike(String commentId) async {
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/comments/$commentId/like'),
      headers: await _headers(),
    );
  }

  // ─── DELETE /comments/{id} ──────────────────────────────────────────────────
  Future<void> deleteComment(String commentId) async {
    final r = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/comments/$commentId'),
      headers: await _headers(),
    );
    _parse(r);
  }

  // ─── GET /topics ────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTopics({String? query}) async {
    final base = Uri.parse('${ApiConstants.baseUrl}/topics');
    final uri = query != null && query.isNotEmpty
        ? base.replace(queryParameters: {'q': query})
        : base;
    final r = await http.get(uri, headers: await _headers());
    final body = _parse(r);
    final data = body['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}
