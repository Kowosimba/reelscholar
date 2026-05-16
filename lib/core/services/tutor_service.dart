import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reelscholar/models/tutor_models.dart';
import '../constants/api_constants.dart';

class TutorService {
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

  // ─── Response parser ────────────────────────────────────────────────────────
  Map<String, dynamic> _parse(http.Response r) {
    final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    if (r.statusCode == 503) {
      throw Exception('AI Tutor is temporarily unavailable. Please try again shortly.');
    }
    if (r.statusCode == 400) {
      throw Exception(body['message'] as String? ?? 'Bad request');
    }
    final msg = body['message'] as String? ?? 'Error ${r.statusCode}';
    throw Exception(msg);
  }

  // ─── GET /tutor/modules ─────────────────────────────────────────────────────
  /// Returns modules grouped by year and semester.
  Future<ModulesResponse> getModules() async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules'),
      headers: await _headers(),
    );
    final body = _parse(r);
    final data = (body['data'] as Map<String, dynamic>?) ?? {};

    // API shape: data.current_semester.modules
    final currentSemester =
        (data['current_semester'] as Map<String, dynamic>?) ?? {};
    final currentList = currentSemester['modules'] as List<dynamic>? ?? [];
    final currentModules = currentList
        .map((m) => TutorModule.fromJson(m as Map<String, dynamic>))
        .toList();

    // API shape: data.other_modules = [{label, modules: [...]}, ...]
    final rawOtherGroups = data['other_modules'] as List<dynamic>? ?? [];
    final relatedModules = <TutorModule>[];
    for (final group in rawOtherGroups) {
      if (group is Map<String, dynamic>) {
        final groupModules = group['modules'] as List<dynamic>? ?? [];
        relatedModules.addAll(
          groupModules
              .map((m) => TutorModule.fromJson(m as Map<String, dynamic>)),
        );
      }
    }

    return ModulesResponse(
      currentModules: currentModules,
      relatedModules: relatedModules,
    );
  }

  // ─── POST /tutor/modules/{module}/start ─────────────────────────────────────
  /// Start or resume a tutor session for a module.
  Future<SessionStartResult> startSession(String moduleId) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/start'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return SessionStartResult.fromJson(
        (body['data'] as Map<String, dynamic>?) ?? {});
  }

  // ─── POST /tutor/modules/{module}/chat ──────────────────────────────────────
  /// Send a user message and receive the AI tutor reply.
  Future<ChatResponse> chat(String moduleId, String message) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/chat'),
      headers: await _headers(),
      body: jsonEncode({'message': message}),
    );
    final body = _parse(r);
    final data = (body['data'] as Map<String, dynamic>?) ?? {};
    return ChatResponse(
      message: data['message']?.toString() ?? '',
      progress: SessionProgress.fromJson(
          (data['progress'] as Map<String, dynamic>?) ?? {}),
    );
  }

  // ─── GET /tutor/modules/{module}/history ────────────────────────────────────
  /// Fetch the conversation history for a module.
  Future<List<ChatMessage>> getHistory(String moduleId) async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/history'),
      headers: await _headers(),
    );
    final body = _parse(r);
    final data = (body['data'] as Map<String, dynamic>?) ?? {};
    final rawMessages = data['messages'];

    if (rawMessages == null) return [];

    List<dynamic> messageList = [];
    if (rawMessages is List) {
      messageList = rawMessages;
    } else if (rawMessages is String && rawMessages.isNotEmpty) {
      try {
        final parsed = jsonDecode(rawMessages);
        if (parsed is List) messageList = parsed;
      } catch (_) {}
    }

    return messageList
        .map((m) {
          if (m is Map<String, dynamic>) {
            return ChatMessage.fromHistoryJson(m);
          }
          // Plain string message
          return ChatMessage.tutor(m.toString());
        })
        .toList();
  }

  // ─── GET /tutor/modules/{module}/flashcards ─────────────────────────────────
  /// Get flashcards for a module.
  Future<List<Flashcard>> getFlashcards(String moduleId) async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/flashcards'),
      headers: await _headers(),
    );
    final body = _parse(r);
    final data = (body['data'] as Map<String, dynamic>?) ?? {};
    final rawCards = data['cards'] as List<dynamic>? ?? [];

    return rawCards.asMap().entries.map((entry) {
      final raw = entry.value;
      if (raw is String) return Flashcard.fromRaw(raw, entry.key);
      if (raw is Map<String, dynamic>) {
        return Flashcard(
          id: raw['id']?.toString() ?? '${entry.key}',
          front: raw['front']?.toString() ??
              raw['concept']?.toString() ??
              raw['question']?.toString() ??
              '',
          back: raw['back']?.toString() ??
              raw['definition']?.toString() ??
              raw['answer']?.toString() ??
              '',
        );
      }
      return Flashcard.fromRaw(raw.toString(), entry.key);
    }).toList();
  }

  // ─── GET /tutor/modules/{module}/concept-map ────────────────────────────────
  /// Get the concept map graph for a module.
  Future<ConceptMap> getConceptMap(String moduleId) async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/concept-map'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return ConceptMap.fromJson((body['data'] as Map<String, dynamic>?) ?? {});
  }

  // ─── GET /tutor/modules/{module}/voice-lesson ───────────────────────────────
  /// Get the voice lesson script for a module.
  Future<VoiceLesson> getVoiceLesson(String moduleId) async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/voice-lesson'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return VoiceLesson.fromJson((body['data'] as Map<String, dynamic>?) ?? {});
  }

  // ─── POST /tutor/modules/{module}/reset ─────────────────────────────────────
  /// Reset/clear a tutor session to start fresh.
  Future<void> resetSession(String moduleId) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/reset'),
      headers: await _headers(),
    );
    _parse(r);
  }
}
