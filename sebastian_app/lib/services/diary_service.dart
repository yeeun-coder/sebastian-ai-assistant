import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sebastian_app/config/api_config.dart';
import 'package:sebastian_app/storage/token_storage.dart';
import 'package:sebastian_app/session/session_expired.dart';

class DiaryService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<List<dynamic>> fetchDiaries({
    String? from,
    String? to,
  }) async {
    final query = <String, String>{};
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;

    final uri = Uri.parse('${ApiConfig.baseUrl}/diary').replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('일기 목록 조회 실패 (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data is! List) {
      throw Exception('일기 응답 형식 오류');
    }
    return data;
  }

  static Future<Map<String, dynamic>> fetchDiary(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/diary/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('일기 조회 실패 (${response.statusCode})');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<Map<String, dynamic>> createDiary(
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/diary'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('일기 저장 실패 (${response.statusCode}): ${response.body}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<Map<String, dynamic>> updateDiary(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/diary/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('일기 수정 실패 (${response.statusCode}): ${response.body}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<void> deleteDiary(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/diary/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('일기 삭제 실패 (${response.statusCode})');
    }
  }
}
