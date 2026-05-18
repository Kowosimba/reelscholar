import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/concept_map_models.dart';

class ConceptMapService {
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

  Future<ConceptMap> get(String moduleId) async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/concept-map'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return ConceptMap.fromJson((body['data'] as Map<String, dynamic>?) ?? {});
  }

  Future<ConceptMap> regenerate(String moduleId) async {
    final r = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tutor/modules/$moduleId/concept-map/regenerate'),
      headers: await _headers(),
    );
    final body = _parse(r);
    return ConceptMap.fromJson((body['data'] as Map<String, dynamic>?) ?? {});
  }
}
