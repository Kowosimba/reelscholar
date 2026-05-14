import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // ─── HTTP helpers ──────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message =
        body['message'] as String? ??
        body['error'] as String? ??
        'Something went wrong (${response.statusCode})';
    throw Exception(message);
  }

  // ─── Token / User persistence ──────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ─── POST /auth/register ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String faculty,
    required int yearLevel,
    required int semester,
    required String degreeProgramme,
    required String role,
    String? studentId,
    String? fcmToken,
  }) async {
    final body = <String, dynamic>{
      'full_name': fullName,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'faculty': faculty,
      'year_level': yearLevel,
      'semester': semester,
      'degree_programme': degreeProgramme,
      'role': role,
      if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
      'fcm_token': ?fcmToken,
    };

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = _parseResponse(response);
    final token = data['data']['token'] as String;
    final user = data['data']['user'] as Map<String, dynamic>;
    await saveToken(token);
    await saveUser(user);
    return data;
  }

  // ─── POST /auth/login ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
    String deviceName = 'mobile',
    String? fcmToken,
  }) async {
    final body = <String, dynamic>{
      'login': login,
      'password': password,
      'device_name': deviceName,
      'fcm_token': ?fcmToken,
    };

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = _parseResponse(response);
    final token = data['data']['token'] as String;
    final user = data['data']['user'] as Map<String, dynamic>;
    await saveToken(token);
    await saveUser(user);
    return data;
  }

  // ─── POST /auth/logout ─────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
        headers: await _headers(auth: true),
      );
    } catch (_) {
      // Always clear local token even if request fails
    } finally {
      await clearToken();
    }
  }

  // ─── POST /auth/logout-all ─────────────────────────────────────────────────
  Future<void> logoutAll() async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logoutAll}'),
        headers: await _headers(auth: true),
      );
    } catch (_) {
    } finally {
      await clearToken();
    }
  }

  // ─── POST /auth/forgot-password ────────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.forgotPassword}'),
      headers: await _headers(),
      body: jsonEncode({'email': email}),
    );
    _parseResponse(response);
  }

  // ─── POST /auth/reset-password ─────────────────────────────────────────────
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resetPassword}'),
      headers: await _headers(),
      body: jsonEncode({
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    _parseResponse(response);
  }

  // ─── GET /auth/me ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}'),
      headers: await _headers(auth: true),
    );
    final data = _parseResponse(response);
    final user = data['data'] as Map<String, dynamic>;
    await saveUser(user);
    return user;
  }

  // ─── GET /auth/verification-status ────────────────────────────────────────
  Future<bool> checkVerificationStatus() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verificationStatus}'),
      headers: await _headers(auth: true),
    );
    final data = _parseResponse(response);
    return data['data']['email_verified'] as bool? ?? false;
  }

  // ─── POST /auth/resend-verification ───────────────────────────────────────
  Future<void> resendVerification() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resendVerification}'),
      headers: await _headers(auth: true),
    );
    _parseResponse(response);
  }

  // ─── GET /auth/verification-link ──────────────────────────────────────────
  Future<String> getVerificationLink() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verificationLink}'),
      headers: await _headers(auth: true),
    );
    final data = _parseResponse(response);
    return data['data']['url'] as String? ?? '';
  }

  // ─── PUT /auth/fcm-token ───────────────────────────────────────────────────
  Future<void> updateFcmToken(String fcmToken) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.fcmToken}'),
      headers: await _headers(auth: true),
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    _parseResponse(response);
  }

  // ─── Metadata ──────────────────────────────────────────────────────────────

  Future<List<String>> getFaculties() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.faculties}'),
      headers: await _headers(),
    );
    final data = _parseResponse(response);
    final list = data['data'] as List<dynamic>;
    return list.map((e) => e['name'] as String).toList();
  }

  Future<List<String>> getProgrammes(String faculty) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.programmes}',
    ).replace(queryParameters: {'faculty': faculty});
    final response = await http.get(uri, headers: await _headers());
    final data = _parseResponse(response);
    final list = data['data'] as List<dynamic>;
    return list.map((e) => e['name'] as String).toList();
  }

  // ─── Change password (uses profile endpoint) ───────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profilePassword}'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      }),
    );
    _parseResponse(response);
  }
}
