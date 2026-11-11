import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sebastian_app/config/api_config.dart';
import 'package:sebastian_app/storage/token_storage.dart';
import 'package:sebastian_app/session/session_expired.dart';

class TodoService {
  Future<List<dynamic>> fetchTodos() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/todos'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('할 일 목록 조회 실패 (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('할 일 응답이 목록 형식이 아닙니다.');
    }
    return decoded;
  }

  Future<void> updateTodo(int id, bool isDone) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/todos/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'isDone': isDone,
      }),
    );
  }

  // To-Do 할 일 추가
  Future<void> createTodo(String title, DateTime dueDate, int leadDays) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/todos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'dueDate': dueDate.toIso8601String(),
        'scheduleLeadDays': leadDays,
      }),
    );

    print(response.statusCode);
    print(response.body);
  }

  Future<void> editTodo(
    int id,
    String title,
    DateTime dueDate,
    int leadDays,
  ) async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }

    await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/todos/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'dueDate': dueDate.toIso8601String(),
        'scheduleLeadDays': leadDays,
      }),
    );
  }

  Future<bool> deleteTodo(int id) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }
    
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/todos/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return res.statusCode == 200;
  }
}