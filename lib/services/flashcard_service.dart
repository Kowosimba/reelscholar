import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/flashcard_models.dart';

class FlashcardService {
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
    final msg = body['message'] as String? ?? 'Error ${r.statusCode}';
    throw Exception(msg);
  }

  Future<FlashcardDeck> generateDeck(String moduleId, {int count = 20}) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/flashcards/generate'),
      headers: await _headers(),
      body: jsonEncode({'count': count}),
    );
    final body = _parse(r);
    return FlashcardDeck.fromJson(
      (body['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<List<FlashcardDeck>> listDecks(String moduleId) async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/flashcards/decks'),
      headers: await _headers(),
    );
    final body = _parse(r);
    final list = (body['data'] as List?) ?? [];
    return list
        .map((e) => FlashcardDeck.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FlashcardDeck> getDeck(String deckId) async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/flashcards/decks/$deckId'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return FlashcardDeck.fromJson(
      (body['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<void> reviewCard({
    required String cardId,
    required int rating,
    required double stability,
    required double difficulty,
    required String state,
    required DateTime dueAt,
  }) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/flashcards/cards/$cardId/review'),
      headers: await _headers(),
      body: jsonEncode({
        'rating': rating,
        'stability': stability,
        'difficulty': difficulty,
        'state': state,
        'due_at': dueAt.toUtc().toIso8601String(),
      }),
    );
    _parse(r);
  }
}
