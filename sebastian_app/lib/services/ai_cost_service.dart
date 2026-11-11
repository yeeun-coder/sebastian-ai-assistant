import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sebastian_app/config/api_config.dart';
import 'package:sebastian_app/storage/token_storage.dart';

class AiCostService {
  AiCostService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw AiCostException('로그인이 필요합니다.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// `GET /ai/usage/summary?days=N`
  Future<Map<String, dynamic>> fetchUsageSummary({int? days}) async {
    final headers = await _authHeaders();
    final query = days != null ? '?days=$days' : '';
    final res = await _client.get(
      _uri('/ai/usage/summary$query'),
      headers: headers,
    );

    if (res.statusCode == 401) throw AiCostException('다시 로그인해 주세요.');
    if (res.statusCode != 200) {
      throw AiCostException('사용량 조회 실패 (${res.statusCode})');
    }

    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  /// `GET /ai/config`
  Future<List<Map<String, dynamic>>> fetchConfigs() async {
    final headers = await _authHeaders();
    final res = await _client.get(_uri('/ai/config'), headers: headers);

    if (res.statusCode != 200) {
      throw AiCostException('설정 조회 실패 (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) throw AiCostException('응답 형식 오류');
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// `PUT /ai/config`
  Future<Map<String, dynamic>> updateConfig({
    required String provider,
    String? model,
    String? apiKey,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{'provider': provider};
    if (model != null) body['model'] = model;
    if (apiKey != null) body['apiKey'] = apiKey;

    final res = await _client.put(
      _uri('/ai/config'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw AiCostException('설정 변경 실패 (${res.statusCode})');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  /// `GET /ai/providers`
  Future<List<Map<String, dynamic>>> fetchProviders() async {
    final headers = await _authHeaders();
    final res = await _client.get(_uri('/ai/providers'), headers: headers);

    if (res.statusCode != 200) {
      throw AiCostException('프로바이더 목록 조회 실패 (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) throw AiCostException('응답 형식 오류');
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// `DELETE /ai/usage`
  Future<void> clearUsage() async {
    final headers = await _authHeaders();
    final res = await _client.delete(_uri('/ai/usage'), headers: headers);

    if (res.statusCode != 200) {
      throw AiCostException('초기화 실패 (${res.statusCode})');
    }
  }
}

class AiCostException implements Exception {
  AiCostException(this.message);
  final String message;

  @override
  String toString() => message;
}
