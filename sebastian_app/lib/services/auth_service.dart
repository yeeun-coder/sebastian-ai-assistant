import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sebastian_app/config/api_config.dart';
import 'package:sebastian_app/storage/token_storage.dart';

class AuthService {
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {

      final data = jsonDecode(response.body);

      return {
        'token': data['access_token'],
        'name': data['nickname'] ?? '',
        'age': data['age'] ?? 0,
        'gender': data['gender'] ?? '',
      };
    }
  return null;
  }

  /// 성공 시 `null`, 실패 시 사용자에게 보여줄 메시지.
  Future<String?> signup({
    required String email,
    required String password,
    required String nickname,
    required String birthDate,
    required String gender,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'nickname': nickname,
        'birthDate': birthDate,
        'gender': gender,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return null;
    }

    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}
    return '회원가입에 실패했습니다 (${response.statusCode})';
  }

  /// 로그인 상태에서 비밀번호 변경 (JWT + 현재 비밀번호 검증)
  Future<String?> updatePasswordAuthenticated(String currentPassword, String newPassword) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return null;
    }

    try {
      final data = jsonDecode(response.body);
      final message = data['message'];
      if (message is List) return message.join('\n');
      if (message is String) return message;
    } catch (_) {}

    return '비밀번호 변경 실패 (${response.statusCode})';
  }

  /// 관리자에게 비밀번호 초기화를 요청한다.
  /// 성공 시 `null`, 실패 시 사용자에게 보여줄 메시지를 반환한다.
  Future<String?> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/password-reset-requests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return null;
    }

    try {
      final data = jsonDecode(response.body);
      final message = data['message'];
      if (message is List) return message.join('\n');
      if (message is String) return message;
    } catch (_) {}

    return '요청 전송에 실패했습니다 (${response.statusCode})';
  }

  Future<String?> updatePassword(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return null;
    }

    try {
      final data = jsonDecode(response.body);

      final message = data['message'];

      if (message is List) {
        return message.join('\n');
      } else if (message is String) {
        return message;
      }
    } catch (e) {
      print(e);
    }

    return '비밀번호 변경 실패 (${response.statusCode})';
  }
}
