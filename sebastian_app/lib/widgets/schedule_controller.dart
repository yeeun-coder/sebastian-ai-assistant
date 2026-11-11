import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/models/schedule_item.dart';
import 'package:sebastian_app/constants/schedule_notification_constants.dart';
import 'package:sebastian_app/services/schedule_dialog_scheduler.dart';
import 'package:sebastian_app/services/schedule_notification_service.dart';
import 'package:sebastian_app/services/schedule_service.dart';
import 'package:sebastian_app/services/todo_service.dart';
import 'package:sebastian_app/session/session_expired.dart';
import 'package:sebastian_app/widgets/briefing_controller.dart';

export 'package:sebastian_app/models/schedule_item.dart'
    show ScheduleItem, formatKoreanTimeAmPm;

class ScheduleController extends GetxController {

  /// To-Do
  var todos = <Map<String, dynamic>>[].obs;
  @override
  void onInit() {
    super.onInit();
    fetchTodos();
  }

  @override
  void onClose() {
    ScheduleDialogScheduler.instance.cancelAll();
    super.onClose();
  }
  final TodoService _todoService = TodoService();

  final Rx<DateTime> selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).obs;

  final Rx<DateTime> focusedDay = DateTime.now().obs;

  /// 날짜별 일정
  final RxMap<DateTime, List<ScheduleItem>> events =
      <DateTime, List<ScheduleItem>>{}.obs;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = _dateOnly(selected);
    focusedDay.value = focused;
  }

  List<ScheduleItem> getSchedules(DateTime day) {
    final key = _dateOnly(day);
    final list = List<ScheduleItem>.from(events[key] ?? []);
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  bool hasEvent(DateTime day) {
    return getSchedules(day).isNotEmpty;
  }

  void addSchedule(ScheduleItem item) {
    final key = _dateOnly(item.dateTime);
    final list = List<ScheduleItem>.from(events[key] ?? []);
    list.add(item);
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    events[key] = list;
    events.refresh();
  }

  /// 캘린더에 올라간 일정 전체(날짜 맵 평탄화).
  List<ScheduleItem> allScheduleItemsFlat({bool includeCompleted = true}) {
    final out = <ScheduleItem>[];
    for (final list in events.values) {
      for (final item in list) {
        if (!includeCompleted && item.isCompleted) continue;
        out.add(item);
      }
    }
    return out;
  }

  void _replaceScheduleItem(String id, ScheduleItem updated) {
    for (final key in events.keys.toList()) {
      final list = events[key];
      if (list == null) continue;
      final idx = list.indexWhere((e) => e.id == id);
      if (idx == -1) continue;
      final next = List<ScheduleItem>.from(list);
      next[idx] = updated;
      events[key] = next;
      events.refresh();
      return;
    }
  }

  Future<void> toggleScheduleCompleted(ScheduleItem item) async {
    final newValue = !item.isCompleted;
    final previous = item;
    _replaceScheduleItem(item.id, item.copyWith(isCompleted: newValue));

    try {
      await _service.patchSchedule(item.id, {'isCompleted': newValue});
      await syncScheduleNotifications();
    } on SessionExpiredException {
      _replaceScheduleItem(item.id, previous);
      await SessionRedirect.toLogin();
    } catch (e) {
      _replaceScheduleItem(item.id, previous);
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('완료 상태 저장 실패: $e')),
      );
    }
  }

  /// 시스템 알림 + 30분 전 인앱 확인 다이얼로그 타이머를 메모리 상태와 맞춥니다.
  Future<void> syncScheduleNotifications() async {
    final items = allScheduleItemsFlat(includeCompleted: false);
    await ScheduleNotificationService.instance.syncScheduleItems(items);
    ScheduleDialogScheduler.instance.sync(items);
  }

  void removeSchedule(String id, DateTime day) {
    final key = _dateOnly(day);
    final list = List<ScheduleItem>.from(events[key] ?? []);
    list.removeWhere((e) => e.id == id);

    if (list.isEmpty) {
      events.remove(key);
    } else {
      events[key] = list;
    }
    events.refresh();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<ScheduleItem> upcomingSchedulesForNotifications() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final list = <ScheduleItem>[];
    for (final entry in events.entries) {
      for (final item in entry.value) {
        final local = item.dateTime.toLocal();
        final day = DateTime(local.year, local.month, local.day);
        if (!day.isBefore(startOfToday) && !item.isCompleted) {
          list.add(item);
        }
      }
    }
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  /// 알림 화면에서 일정별 “몇 분 전” (서버 PATCH + 로컬 알림 재예약).
  Future<void> setScheduleNotificationLead(String scheduleId, int minutes) async {
    for (final key in events.keys.toList()) {
      final list = events[key];
      if (list == null) continue;
      final idx = list.indexWhere((e) => e.id == scheduleId);
      if (idx == -1) continue;

      final old = list[idx];
      try {
        await _service.patchSchedule(scheduleId, {
          'notificationLeadMinutes': minutes,
        });
        _replaceScheduleItem(
          scheduleId,
          old.copyWith(notificationLeadMinutes: minutes),
        );
        await syncScheduleNotifications();
      } catch (e) {
        Get.snackbar('오류', '$e');
      }
      return;
    }
  }

  Future<void> setScheduleAlarm(String scheduleId, bool isAlarmOn) async {
    for (final key in events.keys.toList()) {
      final list = events[key];
      if (list == null) continue;
      final idx = list.indexWhere((e) => e.id == scheduleId);
      if (idx == -1) continue;

      final old = list[idx];
      try {
        await _service.patchSchedule(scheduleId, {'isAlarmOn': isAlarmOn});
        _replaceScheduleItem(scheduleId, old.copyWith(isAlarmOn: isAlarmOn));
        await syncScheduleNotifications();
      } catch (e) {
        // Get.snackbar('오류', '$e');
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('$e'),
          ),
        );
      }
      return;
    }
  }
  String selectedTitle() {
    final now = _dateOnly(DateTime.now());
    if (isSameDay(now, selectedDay.value)) {
      return '오늘 일정';
    }
    return '${selectedDay.value.month}월 ${selectedDay.value.day}일 일정';
  }
  
  final ScheduleService _service = ScheduleService();

  Future<void> loadSchedulesFromDB() async {
    try {
      events.clear();

      final data = await _service.fetchSchedules();

      for (var s in data) {
        final row = Map<String, dynamic>.from(s as Map);
        addSchedule(_scheduleItemFromApiRow(row));
      }

      await syncScheduleNotifications();
    } on SessionExpiredException {
      await SessionRedirect.toLogin();
    } catch (e) {
      // Get.snackbar('오류', '일정을 불러오지 못했습니다. ($e)');
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('일정을 불러오지 못했습니다. ($e)'),
        ),
      );
    }
  }

  Future<void> addScheduleToDB(ScheduleItem item) async {
    try {
      final end = item.endDateTime ?? item.dateTime;
      // final result = await _service.createSchedule({
      //   'title': item.title,
      //   'startDate': item.dateTime.toIso8601String(),
      //   'endDate': end.toIso8601String(),
      //   'content': item.content,
      //   'isImportant': item.isImportant,
      //   'notificationLeadMinutes': item.notificationLeadMinutes,
      // });
      final body = {
        'title': item.title,
        'startDate': _kstNaiveToUtcIso(item.dateTime),
        'endDate': _kstNaiveToUtcIso(end),
        'content': item.content,
        'isImportant': item.isImportant,
        'notificationLeadMinutes': item.notificationLeadMinutes,
      };

      if (item.createDday) {
        body['createDday'] = true;
        body['ddayDateBasis'] = item.ddayBasis ?? 'start';
      }

      print(body);

      final result = await _service.createSchedule(body);

      addSchedule(item);

      // addSchedule(
      //   _scheduleItemFromApiRow(Map<String, dynamic>.from(result)),
      // );

      await syncScheduleNotifications();

      // Get.snackbar("성공", "일정이 저장되었습니다.");
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('일정이 저장되었습니다.'),
        ),
      );
      Get.back();
    } catch (e) {
      // Get.snackbar("오류", "$e");
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    }
  }

  Future<void> updateSchedule(String id, ScheduleItem updatedItem) async {
    try {

      final end = updatedItem.endDateTime ?? updatedItem.dateTime;
      final body = {
        'title': updatedItem.title,
        // 'startDate': updatedItem.dateTime.toIso8601String(),
        // 'endDate': end.toIso8601String(),
        'startDate': _kstNaiveToUtcIso(updatedItem.dateTime),
        'endDate': _kstNaiveToUtcIso(end),
        'content': updatedItem.content,
        'isImportant': updatedItem.isImportant,
        'notificationLeadMinutes': updatedItem.notificationLeadMinutes,
      };

      if (updatedItem.createDday) {
        body['createDday'] = true;
        body['ddayDateBasis'] = updatedItem.ddayBasis ?? 'start';
      }

      print(body);

      await _service.patchSchedule(id, body);

      // 기존 일정 제거
      for (final key in events.keys.toList()) {

        final list = events[key];

        if (list == null) continue;

        list.removeWhere((e) => e.id == id);

        if (list.isEmpty) {
          events.remove(key);
        }
      }

      addSchedule(updatedItem.copyWith(id: id));

      events.refresh();

      await syncScheduleNotifications();

      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text('일정이 수정되었습니다.'),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('일정 수정 실패: $e'),
        ),
      );
    }
  }

  Future<void> deleteSchedule(String id, DateTime dateTime) async {
    try {
      final success = await _service.deleteSchedule(id);

      if (success) {
        final key = _dateOnly(dateTime);
        if (events.containsKey(key)) {
          events[key]!.removeWhere((e) => e.id == id);
          
          if (events[key]!.isEmpty) {
            events.remove(key);
          }
          
          events.refresh();
          await syncScheduleNotifications();
          // Get.snackbar("성공", "일정이 삭제되었습니다.");
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content: Text('일정이 삭제되었습니다.'),
            ),
          );
        }
      }
    } catch (e) {
      // Get.snackbar("오류", "일정 삭제 실패: $e");
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('일정 삭제 실패: $e'),
        ),
      );
    }
  }

  // To-Do
  Future<void> fetchTodos() async {
    try {
      final data = await _todoService.fetchTodos();

      todos.value = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on SessionExpiredException {
      await SessionRedirect.toLogin();
    } catch (e) {
      debugPrint('fetchTodos: $e');
    }
  }
  // To-Do 토글(체크박스)
  Future<void> toggleTodo(int id, bool isDone) async {
    try {
      await _todoService.updateTodo(id, isDone);

      final index = todos.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        todos[index]['isDone'] = isDone;
        todos.refresh();
      }
    } catch (e) {
      print("토글 에러: $e");
    }
  }

  // To-Do 할 일 추가
  Future<void> addTodo(String title, DateTime dueDate, int leadDays) async {
    try {
      await _todoService.createTodo(title, dueDate, leadDays);
      await fetchTodos();
    } catch (e) {
      print("추가 에러: $e");
    }
  }

  Future<void> editTodo(
    int id,
    String title,
    DateTime dueDate,
    int leadDays,
  ) async {
    try {
      await _todoService.editTodo(
        id,
        title,
        dueDate,
        leadDays,
      );

      await fetchTodos();
    } catch (e) {
      print("수정 에러: $e");
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      final success = await _todoService.deleteTodo(id);

      if (success) {
        todos.removeWhere((t) => t['id'] == id);
        todos.refresh();

        // Get.snackbar("성공", "TO-DO가 삭제되었습니다.");
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(
            content: Text("TO-DO가 삭제되었습니다."),
          ),
        );
      }
    } catch (e) {
      // Get.snackbar("오류", "TO-DO 삭제 실패: $e");
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('TO-DO 삭제 실패: $e'),
        ),
      );
    }
  }
}

/// UTC ISO 문자열 → KST 기준 naive DateTime.
/// .toLocal() 대신 고정 +09:00 변환을 사용하여
/// 에뮬레이터(UTC 설정)·해외 기기에서도 항상 한국 시각으로 표시합니다.
DateTime _utcToKstNaive(String isoStr) {
  final utc = DateTime.parse(isoStr).toUtc();
  final kst = utc.add(const Duration(hours: 9));
  return DateTime(kst.year, kst.month, kst.day, kst.hour, kst.minute, kst.second, kst.millisecond);
}

/// KST naive DateTime → UTC ISO 문자열 (서버 전송용).
/// .toUtc() 대신 고정 -09:00 변환을 사용하여 기기 타임존에 무관합니다.
String _kstNaiveToUtcIso(DateTime kst) {
  final utc = DateTime.utc(kst.year, kst.month, kst.day, kst.hour, kst.minute, kst.second, kst.millisecond)
      .subtract(const Duration(hours: 9));
  return utc.toIso8601String();
}

ScheduleItem _scheduleItemFromApiRow(Map<String, dynamic> row) {
  final endRaw = row['endDate'];
  final start = _utcToKstNaive(row['startDate'].toString());
  final end = endRaw != null
      ? _utcToKstNaive(endRaw.toString())
      : null;
  final isAllDay = start.hour == 0 &&
      start.minute == 0 &&
      (end == null || (end.hour == 0 && end.minute == 0));

  return ScheduleItem(
    id: row['id'].toString(),
    title: row['title'] as String,
    dateTime: start,
    endDateTime: end,
    icon: Icons.event,
    content: row['content']?.toString() ?? '',
    isAlarmOn: row['isAlarmOn'] as bool? ?? true,
    isImportant: row['isImportant'] as bool? ?? false,
    isCompleted: row['isCompleted'] as bool? ?? false,
    isAllDay: isAllDay,
    notificationLeadMinutes: _notificationLeadFromRow(row),
    createDday: row['ddayId'] != null,
    ddayBasis: row['ddayDateBasis']?.toString().toLowerCase(),
  );
}

int _notificationLeadFromRow(Map<String, dynamic> row) {
  final v = row['notificationLeadMinutes'] ?? row['notification_lead_minutes'];
  if (v == null) return kScheduleNotificationLeadMinutes;
  if (v is int) return v.clamp(1, 10080);
  if (v is num) return v.toInt().clamp(1, 10080);
  final p = int.tryParse(v.toString());
  if (p != null) return p.clamp(1, 10080);
  return kScheduleNotificationLeadMinutes;
}
