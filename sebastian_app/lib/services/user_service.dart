import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sebastian_app/config/api_config.dart';
import '../storage/token_storage.dart';

class UserService {
  static String? resolveProfileImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiConfig.baseUrl}$path';
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return null;

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    return null;
  }

  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> data) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return null;

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    return null;
  }

  Future<({Map<String, dynamic>? data, String? error})> uploadProfileImage(
    XFile image,
  ) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      return (data: null, error: '로그인이 필요합니다.');
    }

    try {
      final bytes = await image.readAsBytes();
      final filename =
          image.name.isNotEmpty ? image.name : 'profile.jpg';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/users/me/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return (
          data: jsonDecode(response.body) as Map<String, dynamic>,
          error: null,
        );
      }

      String message = '프로필 사진 업로드에 실패했습니다.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['message'] is String) {
          message = body['message'] as String;
        }
      } catch (_) {}

      return (data: null, error: '$message (${response.statusCode})');
    } catch (e) {
      return (data: null, error: '업로드 중 오류: $e');
    }
  }
}
