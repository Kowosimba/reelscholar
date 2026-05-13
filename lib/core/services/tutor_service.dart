import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reelscholar/models/tutor_models.dart';

class TutorService {
  static const String _base =
      'https://reelscholarapi-main-l5f9h5.laravel.cloud/api';
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
      Uri.parse('$_base/tutor/modules'),
      headers: await _headers(),
    );
    final body = _parse(r);
    final data = body['data'] as Map<String, dynamic>;

    final currentList = data['current_modules'] as List<dynamic>? ?? [];
    final currentModules = currentList
        .map((m) => TutorModule.fromJson(m as Map<String, dynamic>))
        .toList();

    // related_modules may be a string (JSON) or list
    List<TutorModule> relatedModules = [];
    final rawRelated = data['related_modules'];
    if (rawRelated is List) {
      relatedModules = rawRelated
          .map((m) => TutorModule.fromJson(m as Map<String, dynamic>))
          .toList();
    } else if (rawRelated is String && rawRelated.isNotEmpty) {
      try {
        final parsed = jsonDecode(rawRelated) as List<dynamic>;
        relatedModules = parsed
            .map((m) => TutorModule.fromJson(m as Map<String, dynamic>))
            .toList();
      } catch (_) {}
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
      Uri.parse('$_base/tutor/modules/$moduleId/start'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return SessionStartResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ─── POST /tutor/modules/{module}/chat ──────────────────────────────────────
  /// Send a user message and receive the AI tutor reply.
  Future<ChatResponse> chat(String moduleId, String message) async {
    final r = await http.post(
      Uri.parse('$_base/tutor/modules/$moduleId/chat'),
      headers: await _headers(),
      body: jsonEncode({'message': message}),
    );
    final body = _parse(r);
    final data = body['data'] as Map<String, dynamic>;
    return ChatResponse(
      message: data['message']?.toString() ?? '',
      progress:
          SessionProgress.fromJson(data['progress'] as Map<String, dynamic>),
    );
  }

  // ─── GET /tutor/modules/{module}/history ────────────────────────────────────
  /// Fetch the conversation history for a module.
  Future<List<ChatMessage>> getHistory(String moduleId) async {
    final r = await http.get(
      Uri.parse('$_base/tutor/modules/$moduleId/history'),
      headers: await _headers(),
    );
    final body = _parse(r);
    final data = body['data'] as Map<String, dynamic>;
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
      Uri.parse('$_base/tutor/modules/$moduleId/flashcards'),
      headers: await _headers(),
    );
    final body = _parse(r);
    final data = body['data'] as Map<String, dynamic>;
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
      Uri.parse('$_base/tutor/modules/$moduleId/concept-map'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return ConceptMap.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ─── GET /tutor/modules/{module}/voice-lesson ───────────────────────────────
  /// Get the voice lesson script for a module.
  Future<VoiceLesson> getVoiceLesson(String moduleId) async {
    final r = await http.get(
      Uri.parse('$_base/tutor/modules/$moduleId/voice-lesson'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return VoiceLesson.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ─── POST /tutor/modules/{module}/reset ─────────────────────────────────────
  /// Reset/clear a tutor session to start fresh.
  Future<void> resetSession(String moduleId) async {
    final r = await http.post(
      Uri.parse('$_base/tutor/modules/$moduleId/reset'),
      headers: await _headers(),
    );
    _parse(r);
  }
}

// ─── Response DTOs ───────────────────────────────────────────────────────────

class ModulesResponse {
  final List<TutorModule> currentModules;
  final List<TutorModule> relatedModules;

  const ModulesResponse({
    required this.currentModules,
    required this.relatedModules,
  });

  /// Group current modules by year, then semester.
  Map<int, Map<int, List<TutorModule>>> get grouped {
    final Map<int, Map<int, List<TutorModule>>> result = {};
    for (final m in currentModules) {
      result.putIfAbsent(m.yearLevel, () => {});
      result[m.yearLevel]!.putIfAbsent(m.semester, () => []);
      result[m.yearLevel]![m.semester]!.add(m);
    }
    return result;
  }
}

class ChatResponse {
  final String message;
  final SessionProgress progress;

  const ChatResponse({required this.message, required this.progress});
}
