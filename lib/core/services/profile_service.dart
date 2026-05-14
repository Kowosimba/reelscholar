// lib/core/services/profile_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reelscholar/core/constants/api_constants.dart';

class NotificationPrefs {
  final bool followers;
  final bool likes;
  final bool comments;
  final bool studyGroups;
  final bool hackathons;
  final bool directMessages;
  final bool announcements;

  const NotificationPrefs({
    this.followers = true,
    this.likes = true,
    this.comments = true,
    this.studyGroups = true,
    this.hackathons = true,
    this.directMessages = true,
    this.announcements = true,
  });

  factory NotificationPrefs.fromJson(Map<String, dynamic> j) =>
      NotificationPrefs(
        followers: _b(j['followers']),
        likes: _b(j['likes']),
        comments: _b(j['comments']),
        studyGroups: _b(j['study_groups']),
        hackathons: _b(j['hackathons']),
        directMessages: _b(j['direct_messages']),
        announcements: _b(j['announcements']),
      );

  Map<String, dynamic> toJson() => {
        'followers': followers,
        'likes': likes,
        'comments': comments,
        'study_groups': studyGroups,
        'hackathons': hackathons,
        'direct_messages': directMessages,
        'announcements': announcements,
      };

  NotificationPrefs copyWith({
    bool? followers,
    bool? likes,
    bool? comments,
    bool? studyGroups,
    bool? hackathons,
    bool? directMessages,
    bool? announcements,
  }) =>
      NotificationPrefs(
        followers: followers ?? this.followers,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        studyGroups: studyGroups ?? this.studyGroups,
        hackathons: hackathons ?? this.hackathons,
        directMessages: directMessages ?? this.directMessages,
        announcements: announcements ?? this.announcements,
      );

  static bool _b(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == 'true' || v == '1';
    return true;
  }
}

class Faculty {
  final String name;
  final List<String> programmes;
  const Faculty({required this.name, required this.programmes});
}

class ProfileService {
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

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ── GET /auth/me ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMe() async {
    final res =
        await http.get(Uri.parse('${ApiConstants.baseUrl}/auth/me'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  // ── PUT /profile ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? studentId,
    String? faculty,
    String? degreeProgramme,
    int? yearLevel,
    int? semester,
    String? bio,
    File? profilePicture,
    bool removeProfilePicture = false,
  }) async {
    final request = http.MultipartRequest(
        'PUT', Uri.parse('${ApiConstants.baseUrl}/profile'));
    final tok = await _token();
    if (tok != null) request.headers['Authorization'] = 'Bearer $tok';
    request.headers['Accept'] = 'application/json';

    if (fullName != null) request.fields['full_name'] = fullName;
    if (email != null) request.fields['email'] = email;
    if (studentId != null) request.fields['student_id'] = studentId;
    if (faculty != null) request.fields['faculty'] = faculty;
    if (degreeProgramme != null) {
      request.fields['degree_programme'] = degreeProgramme;
    }
    if (yearLevel != null) {
      request.fields['year_level'] = '$yearLevel';
    }
    if (semester != null) request.fields['semester'] = '$semester';
    if (bio != null) request.fields['bio'] = bio;
    if (removeProfilePicture) {
      request.fields['remove_profile_picture'] = 'true';
    }
    if (profilePicture != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'profile_picture', profilePicture.path));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  // ── PUT /profile/password ────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/profile/password'),
      headers: await _headers(),
      body: jsonEncode({
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmation,
      }),
    );
    _ok(res);
  }

  // ── DELETE /profile ──────────────────────────────────────────────────────
  Future<void> deleteAccount(String password) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/profile?password=$password'),
      headers: await _headers(),
    );
    _ok(res);
  }

  // ── GET /meta/faculties ──────────────────────────────────────────────────
  Future<List<Faculty>> getFaculties() async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/meta/faculties'), headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final faculties =
        (body['faculties'] as List? ?? []).map((f) => f.toString()).toList();
    final data = body['data'];
    Map<String, dynamic> dataMap = {};
    if (data is Map) {
      dataMap = data as Map<String, dynamic>;
    } else if (data is String) {
      try {
        dataMap = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {}
    }

    return faculties.map((f) {
      final progs = dataMap[f];
      List<String> programmes = [];
      if (progs is List) {
        programmes = progs.map((p) => p.toString()).toList();
      }
      return Faculty(name: f, programmes: programmes);
    }).toList();
  }

  // ── GET /meta/programmes?faculty= ────────────────────────────────────────
  Future<List<String>> getProgrammes(String faculty) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/meta/programmes')
        .replace(queryParameters: {'faculty': faculty});
    final res = await http.get(uri, headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) return data.map((p) => p.toString()).toList();
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return decoded.map((p) => p.toString()).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  // ── GET /profile/notification-preferences ────────────────────────────────
  Future<NotificationPrefs> getNotificationPrefs() async {
    final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/profile/notification-preferences'),
        headers: await _headers());
    _ok(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return NotificationPrefs.fromJson(data);
    }
    if (data is List) {
      final map = <String, dynamic>{};
      for (final item in data) {
        if (item is Map) {
          map[item['key'] as String? ?? ''] = item['value'];
        }
      }
      return NotificationPrefs.fromJson(map);
    }
    return const NotificationPrefs();
  }

  // ── PUT /profile/notification-preferences ────────────────────────────────
  Future<void> updateNotificationPrefs(NotificationPrefs prefs) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/profile/notification-preferences'),
      headers: await _headers(),
      body: jsonEncode(prefs.toJson()),
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
