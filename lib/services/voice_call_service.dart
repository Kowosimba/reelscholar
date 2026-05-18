import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/voice_models.dart';

class VoiceCallService {
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

  Map<String, dynamic> _parse(http.Response r) {
    final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    if (r.statusCode == 429) {
      throw VoiceQuotaException(body['message'] as String? ?? 'Quota reached');
    }
    if (r.statusCode == 503) {
      throw Exception('Voice tutor is temporarily unavailable.');
    }
    final msg = body['message'] as String? ?? 'Error ${r.statusCode}';
    throw Exception(msg);
  }

  Future<VoiceCallSession> startCall(String moduleId) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/voice-call/start'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return VoiceCallSession.fromJson(
      (body['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<VoiceTurnResult> sendTurn(String callId, String transcript) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/voice-calls/$callId/turn'),
      headers: await _headers(),
      body: jsonEncode({'transcript': transcript}),
    );
    final body = _parse(r);
    return VoiceTurnResult.fromJson(
      (body['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<void> endCall(String callId, int durationSeconds) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/voice-calls/$callId/end'),
      headers: await _headers(),
      body: jsonEncode({'duration_seconds': durationSeconds}),
    );
    _parse(r);
  }

  Future<VoiceQuota> getQuota() async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/voice-calls/quota'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return VoiceQuota.fromJson(
      (body['data'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class VoiceQuotaException implements Exception {
  final String message;
  VoiceQuotaException(this.message);
  @override
  String toString() => message;
}
