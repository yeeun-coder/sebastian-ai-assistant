import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sebastian_app/config/api_config.dart';
import 'package:sebastian_app/storage/token_storage.dart';
import 'package:sebastian_app/models/routine.dart';
import 'package:sebastian_app/session/session_expired.dart';

class RoutineService {

  static void _throwIfUnauthorized(int statusCode) {
    if (statusCode == 401) throw const SessionExpiredException();
  }

  static Future<List<Routine>> fetchRoutines() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/routine'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    _throwIfUnauthorized(response.statusCode);

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("루틴 목록 조회 실패: $decoded");
    }

    List<dynamic> list;

    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map) {
      if (decoded['data'] is List) {
        list = decoded['data'];
      } else if (decoded['data'] is Map && decoded['data']['routines'] is List) {
        list = decoded['data']['routines'];
      } else {
        throw Exception("응답 구조 이상: $decoded");
      }
    } else {
      throw Exception("응답 타입 이상");
    }

    return list.map((e) => Routine.fromJson(e)).toList();
  }

  static Future<Set<int>> fetchCompletions(String dateYmd) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/routine/completions?date=$dateYmd'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    _throwIfUnauthorized(response.statusCode);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('루틴 완료 목록 조회 실패: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final ids = decoded['routineIds'];
    if (ids is! List) return {};
    return ids.map((e) => (e as num).toInt()).toSet();
  }

  static Future<void> setRoutineCompletion(
    int id,
    String dateYmd,
    bool completed,
  ) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    final response = completed
        ? await http.post(
            Uri.parse('${ApiConfig.baseUrl}/routine/$id/complete'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'date': dateYmd}),
          )
        : await http.delete(
            Uri.parse(
              '${ApiConfig.baseUrl}/routine/$id/complete?date=$dateYmd',
            ),
            headers: {
              'Authorization': 'Bearer $token',
            },
          );

    _throwIfUnauthorized(response.statusCode);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('루틴 완료 상태 변경 실패');
    }
  }

  // POST
  static Future<void> createRoutine(Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/routine'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    _throwIfUnauthorized(response.statusCode);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("루틴 생성 실패: ${response.body}");
    }
  }
  
  static Future<void> updateRoutineActive(int id, bool isActive) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/routine/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "isActive": isActive,
      }),
    );

    _throwIfUnauthorized(response.statusCode);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("루틴 상태 변경 실패");
    }
  }

  // 삭제
  static Future<void> deleteRoutine(int id) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/routine/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    _throwIfUnauthorized(response.statusCode);

    // print("삭제 status: ${response.statusCode}");
    // print("삭제 body: ${response.body}");

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("삭제 실패");
    }
  }

  // 수정
  static Future<void> updateRoutine(int id, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/routine/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    _throwIfUnauthorized(response.statusCode);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("수정 실패: ${response.body}");
    }
  }
}