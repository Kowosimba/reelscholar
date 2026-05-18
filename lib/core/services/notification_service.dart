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

  /// GET /notifications — returns notifications list + unread count.
  Future<({List<AppNotification> items, int unreadCount})> getNotifications() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications'),
      headers: await _headers(),
    );
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final unreadCount = (body['unread_count'] as num?)?.toInt() ?? 0;
    final data = body['data'];
    List<dynamic> rawList = [];
    if (data is Map<String, dynamic>) {
      rawList = data['data'] as List? ?? [];
    } else if (data is List) {
      rawList = data;
    }
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
    return (items: items, unreadCount: unreadCount);
  }

  /// POST /notifications/read — pass null ids to mark all as read.
  Future<void> markRead({List<String>? ids}) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/notifications/read'),
      headers: await _headers(),
      body: jsonEncode({'ids': ids}),
    );
    _assertOk(res);
  }
}
