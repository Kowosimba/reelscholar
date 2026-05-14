import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reelscholar/models/quiz_models.dart';
import '../constants/api_constants.dart';

/// Quiz API — OpenAPI tags `Quiz` + `Tutor` (`/quizzes/*`, `/tutor/modules/{id}/quiz*`).
class QuizService {
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

  void _assertOk(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = body['message'] as String?;
      throw Exception(msg ?? 'Request failed (${res.statusCode})');
    } catch (_) {
      throw Exception('Request failed (${res.statusCode})');
    }
  }

  /// GET /quizzes/{quiz}
  Future<Quiz> getQuiz(String quizId) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/quizzes/$quizId'),
      headers: await _headers(),
    );
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Quiz.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// POST /quizzes/{quiz}/submit
  Future<QuizResult> submitQuiz({
    required String quizId,
    required List<Map<String, dynamic>> answers,
    int? durationSeconds,
  }) async {
    final payload = <String, dynamic>{'answers': answers};
    if (durationSeconds != null) {
      payload['duration_seconds'] = durationSeconds;
    }
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/quizzes/$quizId/submit'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return QuizResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// GET /quizzes/module/{moduleId}/attempts (paginated)
  Future<List<QuizAttempt>> getAttempts(String moduleId, {int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/quizzes/module/$moduleId/attempts',
    ).replace(queryParameters: {'page': '$page'});
    final res = await http.get(uri, headers: await _headers());
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    List<dynamic> items = [];
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      items = data['data'] as List? ?? [];
    }
    return items
        .map((i) => QuizAttempt.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  /// GET /tutor/modules/{module}/quiz — returns null if none (404).
  Future<QuizSuggestion?> getCurrentQuiz(String moduleId) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/quiz'),
      headers: await _headers(),
    );
    if (res.statusCode == 404) return null;
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return QuizSuggestion.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// POST /tutor/modules/{module}/quiz/generate (201 Created)
  Future<Quiz> generateQuiz(String moduleId) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/quiz/generate'),
      headers: await _headers(),
    );
    if (res.statusCode == 400) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(
        body['message'] as String? ??
            'Complete at least one topic before generating a quiz.',
      );
    }
    _assertOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Quiz.fromJson(body['data'] as Map<String, dynamic>);
  }
}
