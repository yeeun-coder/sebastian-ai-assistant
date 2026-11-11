import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sebastian_app/config/api_config.dart';
import 'package:sebastian_app/storage/token_storage.dart';
import 'package:sebastian_app/session/session_expired.dart';

class ScheduleService {
  Future<List<dynamic>> fetchSchedules() async {
    final token = await TokenStorage.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/schedule'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('일정 목록 조회 실패 (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('일정 응답 형식 오류');
    }
    final items = data['items'];
    if (items is! List) {
      throw Exception('일정 items 형식 오류');
    }
    return items;
  }

  /// 시작이 지났는데 미완료인 일정 목록 — id·title·startTime만.
  Future<List<Map<String, dynamic>>> fetchOverdue() async {
    final token = await TokenStorage.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/schedule/overdue'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('지난 일정 조회 실패 (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return const [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) async {
    final token = await TokenStorage.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/schedule'),
      body: jsonEncode(data),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print(response.statusCode);
    print(response.body);
    
    return jsonDecode(response.body);
  }

  Future<void> patchSchedule(String id, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();

    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/schedule/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print(res.statusCode);
    print(res.body);

    if (res.statusCode != 200) {
      throw Exception('일정 수정 실패 (${res.statusCode})');
    }
  }

  Future<bool> deleteSchedule(String id) async {
    final token = await TokenStorage.getToken();
    
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/schedule/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return res.statusCode == 200;
  }
}