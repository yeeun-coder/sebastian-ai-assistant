import 'package:get/get.dart';
import 'package:sebastian_app/models/diary_entry.dart';
import 'package:sebastian_app/services/diary_service.dart';
import 'package:sebastian_app/session/session_expired.dart';

class DiaryController extends GetxController {
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs;
  final entriesByDate = <String, List<DiaryEntry>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    selectedDate.value = DateTime(now.year, now.month, now.day);
    loadAroundSelectedDate();
  }

  static String formatYmd(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DiaryEntry> entriesFor(DateTime date) {
    return List<DiaryEntry>.from(
      entriesByDate[formatYmd(_dateOnly(date))] ?? const [],
    );
  }

  bool hasEntry(DateTime date) => entriesFor(date).isNotEmpty;

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = _dateOnly(date);
    await loadAroundSelectedDate();
  }

  Future<void> loadAroundSelectedDate() async {
    final center = _dateOnly(selectedDate.value);
    final from = center.subtract(const Duration(days: 31));
    final to = center.add(const Duration(days: 31));
    await _fetchAndMerge(from, to, replaceAll: true);
  }

  /// 달력 펼침·월 이동 시 해당 월(전후 패딩 포함) 일기를 추가 로드합니다.
  Future<void> loadForMonth(DateTime month) async {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final from = first.subtract(const Duration(days: 7));
    final to = last.add(const Duration(days: 7));
    await _fetchAndMerge(from, to, replaceAll: false);
  }

  void _sortEntries(List<DiaryEntry> entries) {
    entries.sort((a, b) => b.id.compareTo(a.id));
  }

  Map<String, List<DiaryEntry>> _groupByDate(List<dynamic> raw) {
    final grouped = <String, List<DiaryEntry>>{};
    for (final item in raw) {
      final entry = DiaryEntry.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      grouped.putIfAbsent(entry.diaryDate, () => []).add(entry);
    }
    for (final list in grouped.values) {
      _sortEntries(list);
    }
    return grouped;
  }

  void _mergeGroupedEntries(Map<String, List<DiaryEntry>> fetched) {
    for (final entry in fetched.entries) {
      final existing = entriesByDate[entry.key];
      if (existing == null) {
        entriesByDate[entry.key] = entry.value;
        continue;
      }

      final byId = {for (final item in existing) item.id: item};
      for (final item in entry.value) {
        byId[item.id] = item;
      }
      final merged = byId.values.toList();
      _sortEntries(merged);
      entriesByDate[entry.key] = merged;
    }
  }

  Future<void> _fetchAndMerge(
    DateTime from,
    DateTime to, {
    required bool replaceAll,
  }) async {
    isLoading.value = true;
    try {
      final raw = await DiaryService.fetchDiaries(
        from: formatYmd(from),
        to: formatYmd(to),
      );

      final fetched = _groupByDate(raw);
      if (replaceAll) {
        entriesByDate.assignAll(fetched);
      } else {
        _mergeGroupedEntries(fetched);
        entriesByDate.refresh();
      }
    } on SessionExpiredException {
      await SessionRedirect.toLogin();
    } catch (e) {
      Get.snackbar('오류', '일기를 불러오지 못했습니다. ($e)');
    } finally {
      isLoading.value = false;
    }
  }

  void _upsertEntry(DiaryEntry entry) {
    final list = entriesByDate.putIfAbsent(entry.diaryDate, () => []);
    final index = list.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      list[index] = entry;
    } else {
      list.insert(0, entry);
    }
    _sortEntries(list);
  }

  Future<DiaryEntry?> saveDiary({
    required String diaryDate,
    required String content,
    String? title,
    String? mood,
    int? existingId,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'diaryDate': diaryDate,
        'content': content,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (mood != null && mood.trim().isNotEmpty) 'mood': mood.trim(),
      };

      final Map<String, dynamic> result;
      if (existingId != null) {
        result = await DiaryService.updateDiary(existingId, body);
      } else {
        result = await DiaryService.createDiary(body);
      }

      final entry = DiaryEntry.fromJson(result);
      _upsertEntry(entry);
      entriesByDate.refresh();
      return entry;
    } on SessionExpiredException {
      await SessionRedirect.toLogin();
      return null;
    } catch (e) {
      Get.snackbar('오류', '$e');
      return null;
    }
  }

  Future<bool> deleteDiary(int id, String diaryDate) async {
    try {
      await DiaryService.deleteDiary(id);
      final list = entriesByDate[diaryDate];
      if (list != null) {
        list.removeWhere((entry) => entry.id == id);
        if (list.isEmpty) {
          entriesByDate.remove(diaryDate);
        }
      }
      entriesByDate.refresh();
      return true;
    } on SessionExpiredException {
      await SessionRedirect.toLogin();
      return false;
    } catch (e) {
      Get.snackbar('오류', '$e');
      return false;
    }
  }
}
