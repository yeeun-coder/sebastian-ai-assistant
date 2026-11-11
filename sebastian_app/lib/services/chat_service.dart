import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sebastian_app/config/api_config.dart';
import 'package:sebastian_app/storage/token_storage.dart';

/// Nest `/chat/*` (JWT). 로컬 서버 전제 — [ApiConfig.baseUrl].
class ChatService {
  ChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw ChatApiException('로그인이 필요합니다.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// `GET /chat/messages` — 시간순 JSON 배열
  Future<List<Map<String, dynamic>>> fetchMessages() async {
    final headers = await _authHeaders();
    final res = await _client.get(_uri('/chat/messages'), headers: headers);

    if (res.statusCode == 401) {
      throw ChatApiException('다시 로그인해 주세요.');
    }
    if (res.statusCode != 200) {
      throw ChatApiException('메시지를 불러오지 못했습니다 (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw ChatApiException('응답 형식이 올바르지 않습니다.');
    }
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// `POST /chat/messages` — `{ userMessage, assistantMessage }`.
  /// [contextHint]가 있으면 이번 한 번의 AI 호출에만 시스템 프롬프트로 주입된다 (DB 미저장).
  Future<Map<String, dynamic>> sendMessage(
    String text, {
    String? contextHint,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ChatApiException('메시지를 입력해 주세요.');
    }

    final headers = await _authHeaders();
    final body = <String, dynamic>{'message': trimmed};
    final hint = contextHint?.trim();
    if (hint != null && hint.isNotEmpty) {
      body['contextHint'] = hint;
    }
    final res = await _client.post(
      _uri('/chat/messages'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 401) {
      throw ChatApiException('다시 로그인해 주세요.');
    }
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ChatApiException('전송에 실패했습니다 (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw ChatApiException('응답 형식이 올바르지 않습니다.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  /// `POST /chat/overdue-briefing` — 지난 일정 목록을 보내면 활성 페르소나 말투로
  /// 브리핑 문장을 생성해 반환한다 (DB 미저장). 항목이 없으면 빈 문자열.
  Future<String> fetchOverdueBriefing(
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) return '';
    final headers = await _authHeaders();
    final res = await _client.post(
      _uri('/chat/overdue-briefing'),
      headers: headers,
      body: jsonEncode({'items': items}),
    );

    if (res.statusCode == 401) {
      throw ChatApiException('다시 로그인해 주세요.');
    }
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ChatApiException('브리핑 생성에 실패했습니다 (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw ChatApiException('응답 형식이 올바르지 않습니다.');
    }
    return decoded['text']?.toString() ?? '';
  }
}

class ChatApiException implements Exception {
  ChatApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
