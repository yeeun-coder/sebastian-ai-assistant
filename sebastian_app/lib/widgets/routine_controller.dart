import 'package:get/get.dart';
import 'package:sebastian_app/models/routine.dart';
import 'package:sebastian_app/services/routine_service.dart';
import 'package:sebastian_app/session/session_expired.dart';

class RoutineController extends GetxController {
  var routines = <Routine>[].obs;
  final selectedDate = DateTime.now().obs;

  // 카테고리별로 묶인 데이터
  var grouped = <String, List<Routine>>{}.obs;

  // 토글 상태
  var openState = <String, bool>{}.obs;

  final _completionsByDate = <String, Set<int>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    try {
      final data = await RoutineService.fetchRoutines();
      routines.value = data;
      await _loadCompletionsForSelectedDate();
      _groupByCategory();
    } on SessionExpiredException {
      await SessionRedirect.toLogin();
    } catch (e) {
      Get.snackbar('오류', '루틴을 불러오지 못했습니다. ($e)');
    }
  }

  String formatYmd(DateTime date) {
    final d = _dateOnly(date);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> ensureCompletionsLoaded(DateTime date) async {
    final key = formatYmd(date);
    if (_completionsByDate.containsKey(key)) return;
    await _loadCompletionsForDate(date);
  }

  Future<void> _loadCompletionsForSelectedDate() async {
    await _loadCompletionsForDate(selectedDate.value);
  }

  Future<void> _loadCompletionsForDate(DateTime date) async {
    final key = formatYmd(date);
    final ids = await RoutineService.fetchCompletions(key);
    _completionsByDate[key] = ids;
    _completionsByDate.refresh();
  }

  bool isCompletedOnDate(int routineId, DateTime date) {
    final key = formatYmd(date);
    return _completionsByDate[key]?.contains(routineId) ?? false;
  }

  bool isCompleted(Routine routine) =>
      isCompletedOnDate(routine.id, selectedDate.value);

  void _groupByCategory() {
    final map = <String, List<Routine>>{};
    final target = _dateOnly(selectedDate.value);

    for (var r in routines) {
      if (!matchesDate(r, target)) continue;
      if (!map.containsKey(r.category)) {
        map[r.category] = [];
      }
      map[r.category]!.add(r);
    }

    grouped.assignAll(map);

    // 처음엔 다 열어놓기
    for (var key in map.keys) {
      openState[key] = true;
    }
  }

  void toggle(String category) {
    openState[category] = !(openState[category] ?? true);
    update();
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = _dateOnly(date);
    try {
      await _loadCompletionsForSelectedDate();
      _groupByCategory();
    } on SessionExpiredException {
      await SessionRedirect.toLogin();
    } catch (e) {
      Get.snackbar('오류', '루틴 완료 상태를 불러오지 못했습니다. ($e)');
    }
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool matchesDate(Routine routine, DateTime date) => _matchesDate(routine, date);

  bool hasRoutineOnDate(DateTime date) {
    final target = _dateOnly(date);
    return routines.any((r) => _matchesDate(r, target));
  }

  bool _matchesDate(Routine routine, DateTime date) {
    final interval = (routine.repeatInterval ?? 'WEEKLY').toUpperCase();
    switch (interval) {
      case 'DAILY':
        return true;
      case 'WEEKLY':
        return _matchesWeekly(routine, date);
      case 'BIWEEKLY':
        return _matchesBiweekly(routine, date);
      case 'MONTHLY':
        return routine.repeatDayOfMonth == date.day;
      case 'YEARLY':
        return routine.repeatMonth == date.month &&
            routine.repeatDayOfMonth == date.day;
      default:
        return _matchesWeekly(routine, date);
    }
  }

  static const _koDayToCode = {
    '월': 'MON',
    '화': 'TUE',
    '수': 'WED',
    '목': 'THU',
    '금': 'FRI',
    '토': 'SAT',
    '일': 'SUN',
  };

  static const _longEnToCode = {
    'MONDAY': 'MON',
    'TUESDAY': 'TUE',
    'WEDNESDAY': 'WED',
    'THURSDAY': 'THU',
    'FRIDAY': 'FRI',
    'SATURDAY': 'SAT',
    'SUNDAY': 'SUN',
  };

  String _repeatDayTokenToCode(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (_koDayToCode.containsKey(t)) return _koDayToCode[t]!;
    final u = t.toUpperCase();
    if (_longEnToCode.containsKey(u)) return _longEnToCode[u]!;
    if (u.length == 3) return u;
    return u;
  }

  bool _matchesWeekly(Routine routine, DateTime date) {
    final raw = routine.repeatDays ?? '';
    final parts = raw.split(RegExp(r'[,，、\s]+'));
    final days = <String>{};
    for (final p in parts) {
      final code = _repeatDayTokenToCode(p);
      if (code.isNotEmpty) days.add(code);
    }
    if (days.isEmpty) return true;
    return days.contains(_weekdayCode(date.weekday));
  }

  bool _matchesBiweekly(Routine routine, DateTime date) {
    if (!_matchesWeekly(routine, date)) return false;
    final anchorStr = routine.biweeklyAnchorDate;
    if (anchorStr == null || anchorStr.trim().isEmpty) return true;
    final anchor = _parseYmd(anchorStr.trim());
    if (anchor == null) return true;
    final a = _dateOnly(anchor);
    final d = _dateOnly(date);
    final weekDiff = d.difference(a).inDays ~/ 7;
    return weekDiff % 2 == 0;
  }

  DateTime? _parseYmd(String s) {
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  String _weekdayCode(int weekday) {
    const map = <int, String>{
      DateTime.monday: 'MON',
      DateTime.tuesday: 'TUE',
      DateTime.wednesday: 'WED',
      DateTime.thursday: 'THU',
      DateTime.friday: 'FRI',
      DateTime.saturday: 'SAT',
      DateTime.sunday: 'SUN',
    };
    return map[weekday] ?? 'MON';
  }

  void toggleCompletion(Routine routine) async {
    final dateKey = formatYmd(selectedDate.value);
    final wasCompleted = isCompleted(routine);
    final nextCompleted = !wasCompleted;

    final current = _completionsByDate[dateKey] ?? <int>{};
    final updated = Set<int>.from(current);
    if (nextCompleted) {
      updated.add(routine.id);
    } else {
      updated.remove(routine.id);
    }
    _completionsByDate[dateKey] = updated;
    _completionsByDate.refresh();
    _groupByCategory();

    try {
      await RoutineService.setRoutineCompletion(
        routine.id,
        dateKey,
        nextCompleted,
      );
    } on SessionExpiredException {
      await SessionRedirect.toLogin();
    } catch (e) {
      _completionsByDate[dateKey] = current;
      _completionsByDate.refresh();
      _groupByCategory();
      Get.snackbar('오류', '루틴 완료 상태 저장에 실패했습니다.');
    }
  }

  void deleteRoutine(Routine routine) async {
    routines.removeWhere((r) => r.id == routine.id);
    for (final key in _completionsByDate.keys.toList()) {
      _completionsByDate[key]!.remove(routine.id);
    }
    _completionsByDate.refresh();
    _groupByCategory();

    try {
      await RoutineService.deleteRoutine(routine.id);
    } on SessionExpiredException {
      await SessionRedirect.toLogin();
    } catch (e) {
      fetch();
    }
  }
}
