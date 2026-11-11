import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/routes/app_routes.dart';
import 'package:sebastian_app/services/schedule_service.dart';
import 'package:sebastian_app/services/chat_service.dart';
import 'package:sebastian_app/session/session_expired.dart';

/// 단일 미완료 일정에 대한 미루기 컨텍스트.
/// AI 호출 시 시스템 프롬프트에 주입해 "어떤 일정?" 되묻기를 막는다.
class PendingReschedule {
  PendingReschedule({
    required this.scheduleId,
    required this.title,
    required this.originalTime,
  });

  final int scheduleId;
  final String title;
  final DateTime originalTime;
}

/// 지난 미완료 일정에 대해 챗에 한 번씩 물어보는 컨트롤러.
/// - 앱 진입 시 [checkOverdue] 1회 호출 (이후 홈 재진입 시엔 [_sessionChecked]로 차단)
/// - 같은 세션에서 이미 물어본 id는 [askedIds]로 차단 (앱 재시작 시 초기화)
class OverdueChatController extends GetxController {
  final ScheduleService _service = ScheduleService();
  final ChatService _chatService = ChatService();

  /// 이번 앱 세션에서 overdue 체크를 이미 수행했으면 true.
  /// TC 위젯이 재생성(홈 재진입)되어도 중복 AI 호출을 막는다.
  bool _sessionChecked = false;

  /// 이번 세션에서 안내한 일정 id
  final Set<int> askedIds = <int>{};

  /// 챗 위젯이 소비하면 null로 비움
  final Rxn<String> pendingBotText = Rxn<String>();

  /// 단일 안내 직후의 컨텍스트. "완료/아니" 단축 PATCH·AI 미루기 주입에 사용.
  /// AI가 일정을 수정하면 즉시 null.
  PendingReschedule? pendingReschedule;

  static const _completionTriggers = <String>{
    '완료', '완료했어', '완료함', '완료했어요',
    '했어', '했어요', '끝났어', '끝났어요',
    '됐어', '됐어요', '이미 했어', '이미했어',
    '아니', '아니요', '취소',
  };

  Future<void> checkOverdue() async {
    if (_sessionChecked) return;
    _sessionChecked = true;

    List<Map<String, dynamic>> list;
    try {
      list = await _service.fetchOverdue();
    } on SessionExpiredException {
      return;
    } catch (e) {
      debugPrint('overdue fetch failed: $e');
      return;
    }

    final fresh = <Map<String, dynamic>>[];
    for (final e in list) {
      final raw = e['id'];
      final id = raw is num ? raw.toInt() : int.tryParse('$raw');
      if (id == null) continue;
      if (askedIds.contains(id)) continue;
      fresh.add({
        'id': id,
        'title': e['title']?.toString() ?? '일정',
        'startTime': e['startTime']?.toString(),
      });
    }
    if (fresh.isEmpty) return;

    for (final e in fresh) {
      askedIds.add(e['id'] as int);
    }

    // 브리핑은 활성 페르소나 말투로 서버(LLM)에서 생성한다. 항목 표기는 사람이 읽기 쉬운 한국 시간.
    final briefItems = fresh.map((m) {
      return <String, dynamic>{
        'title': m['title'],
        'startTime': _fmtKr(m['startTime'] as String?),
      };
    }).toList();

    if (fresh.length == 1) {
      final m = fresh.first;
      pendingReschedule = PendingReschedule(
        scheduleId: m['id'] as int,
        title: m['title'] as String,
        originalTime:
            DateTime.tryParse(m['startTime']?.toString() ?? '') ?? DateTime.now(),
      );
    } else {
      pendingReschedule = null;
    }

    // 페르소나 말투 브리핑 생성. 실패 시 기존 템플릿으로 폴백.
    String? text;
    try {
      final generated = await _chatService.fetchOverdueBriefing(briefItems);
      if (generated.trim().isNotEmpty) text = generated.trim();
    } catch (e) {
      debugPrint('overdue briefing generate failed: $e');
    }
    text ??= _fallbackBriefingText(fresh);

    pendingBotText.value = text;

    if (Get.currentRoute != AppRoutes.home) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// 단답 "완료/아니"면 즉시 PATCH. 처리했으면 true.
  Future<bool> tryHandleCompletionShortcut(String text) async {
    final pending = pendingReschedule;
    if (pending == null) return false;

    final norm = text.trim().replaceAll(RegExp(r'[.!?\s]+$'), '');
    if (!_completionTriggers.contains(norm)) {
      // 단축 윈도우(완료/아니)는 단답일 때만. 미루기 본문은 buildContextHint로 별도 처리.
      return false;
    }

    try {
      await _service.patchSchedule(pending.scheduleId.toString(), {
        'isCompleted': true,
      });
      pendingReschedule = null;
      return true;
    } catch (e) {
      debugPrint('overdue complete PATCH failed: $e');
      pendingReschedule = null;
      return false;
    }
  }

  /// AI 호출 시 함께 보낼 컨텍스트(시스템 프롬프트에 주입됨). 없으면 null.
  String? buildContextHint() {
    final p = pendingReschedule;
    if (p == null) return null;
    return '미루기 대상 일정: id=${p.scheduleId}, title="${p.title}", originalTime=${p.originalTime.toUtc().toIso8601String()}\n'
        '사용자가 미루겠다고 했으니 언제로 바꿀지 파악해서 update_schedule 도구를 호출하세요.\n'
        '사용자 메시지에 구체적인 시간 언급이 없으면 "지금(현재 시각)부터 24시간 뒤"로 설정하세요. '
        '새 시각은 반드시 현재보다 미래여야 합니다 (지난 일정 시각 기준이 아니라 현재 기준).\n'
        'KST 기준 HH:mm으로 startTime/endTime을 채우고, date는 새 날짜(YYYY-MM-DD)로 넣으세요.';
  }

  void clearReschedule() {
    pendingReschedule = null;
  }

  void consumeBotText() {
    pendingBotText.value = null;
  }

  /// LLM 브리핑 생성 실패 시 사용하는 기본 템플릿(페르소나 미적용).
  String _fallbackBriefingText(List<Map<String, dynamic>> fresh) {
    if (fresh.length == 1) {
      final m = fresh.first;
      final stStr = _fmtKr(m['startTime'] as String?);
      return '⏰ "${m['title']}" ($stStr)이 지났는데 완료 안 됐어요. 미룰까요?';
    }
    final lines = fresh.map((m) {
      final stStr = _fmtKr(m['startTime'] as String?);
      return '• ${m['title']} ($stStr)';
    }).join('\n');
    return '⏰ 지난 일정이 ${fresh.length}개 있어요.\n$lines\n미룰 일정이 있으면 말씀해 주세요.';
  }

  String _fmtKr(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    final ampm = d.hour < 12 ? '오전' : '오후';
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.month}월 ${d.day}일 $ampm $h12시 $mm분';
  }
}
