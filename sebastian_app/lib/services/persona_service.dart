import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sebastian_app/config/api_config.dart';
import 'package:sebastian_app/storage/token_storage.dart';

class PersonaService {
  /// 서버 페르소나 목록 조회 → { type: id } 매핑 반환
  /// 예: { 'basic': 1, 'mother': 2, 'minister': 3, 'teacher': 4, 'sage': 5 }
  static Future<Map<String, int>> getPersonaTypeMap() async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/chat/personas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('페르소나 목록 조회 실패 (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('응답 형식 이상');
    }

    final map = <String, int>{};
    for (final item in decoded) {
      if (item is Map && item['type'] is String && item['id'] is int) {
        map[item['type'] as String] = item['id'] as int;
      }
    }
    return map;
  }

  /// 활성 페르소나 변경
  static Future<void> setActivePersona(int personaId) async {
    final token = await TokenStorage.getToken();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/chat/persona-profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'activePersonaId': personaId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('페르소나 변경 실패 (${response.statusCode})');
    }
  }
}
