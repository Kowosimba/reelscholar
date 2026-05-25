import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reelscholar/core/constants/api_constants.dart';
import 'package:reelscholar/models/notification_model.dart';

class NotificationService {
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

  void _assertOk(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Request failed (${res.statusCode})');
    } catch (_) {
      throw Exception('Request failed (${res.statusCode})');
    }
  }

  /// GET /notifications — returns notifications list + unread count + hasMore.
  Future<({List<AppNotification> items, int unreadCount, bool hasMore})>
      getNotifications({int page = 1}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/notifications')
        .replace(queryParameters: {'page': '$page'});
    final res = await http.get(uri, headers: await _headers());
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final unreadCount = (body['unread_count'] as num?)?.toInt() ?? 0;
    final data = body['data'];
    List<dynamic> rawList = [];
    int currentPage = page;
    int lastPage = page;
    if (data is Map<String, dynamic>) {
      rawList = data['data'] as List? ?? [];
      currentPage = (data['current_page'] as num?)?.toInt() ?? page;
      lastPage = (data['last_page'] as num?)?.toInt() ?? page;
    } else if (data is List) {
      rawList = data;
    }
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
    return (
      items: items,
      unreadCount: unreadCount,
      hasMore: currentPage < lastPage,
    );
  }

  /// POST /notifications/read — pass null ids to mark all as read.
  Future<void> markRead({List<String>? ids}) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/notifications/read'),
      headers: await _headers(),
      body: jsonEncode(ids != null ? {'ids': ids} : {}),
    );
    _assertOk(res);
  }

  /// GET /profile/notification-preferences
  Future<Map<String, bool>> getPreferences() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/profile/notification-preferences'),
      headers: await _headers(),
    );
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return data.map((k, v) => MapEntry(k, v == true));
  }

  /// PUT /profile/notification-preferences — send only changed keys.
  Future<void> updatePreferences(Map<String, bool> prefs) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/profile/notification-preferences'),
      headers: await _headers(),
      body: jsonEncode(prefs),
    );
    _assertOk(res);
  }
}
