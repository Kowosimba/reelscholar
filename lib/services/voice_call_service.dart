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

  Map<String, dynamic> _parseOk(http.Response r) {
    final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = body['message'] as String? ?? 'Error ${r.statusCode}';
    throw Exception(msg);
  }

  Future<VoiceCallSession> startCall(String moduleId) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/voice-call/start'),
      headers: await _headers(),
    );
    if (r.statusCode == 400) {
      final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final msg = body['message'] as String? ??
          'Open the Tutor tab for this module first, then come back.';
      throw Exception(msg);
    }
    if (r.statusCode == 429) {
      final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final msg = body['message'] as String? ?? "You've used all your voice turns for today.";
      throw VoiceQuotaException(msg);
    }
    final body = _parseOk(r);
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
    if (r.statusCode == 409) throw const VoiceCallEndedException();
    if (r.statusCode == 503) throw const VoiceTutorUnavailableException();
    if (r.statusCode == 429) {
      final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final msg = body['message'] as String? ?? 'Rate limited.';
      final retryAfter = (body['retry_after'] as num?)?.toInt() ?? 0;
      throw VoiceQuotaException(msg, retryAfterSeconds: retryAfter);
    }
    final body = _parseOk(r);
    return VoiceTurnResult.fromJson(
      (body['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<VoiceEndSummary> endCall(String callId, int durationSeconds) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/voice-calls/$callId/end'),
      headers: await _headers(),
      body: jsonEncode({'duration_seconds': durationSeconds}),
    );
    final body = _parseOk(r);
    return VoiceEndSummary.fromJson(
      (body['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<VoiceQuota> getQuota() async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/voice-calls/quota'),
      headers: await _headers(),
    );
    final body = _parseOk(r);
    return VoiceQuota.fromJson(
      (body['data'] as Map<String, dynamic>?) ?? {},
    );
  }
}
