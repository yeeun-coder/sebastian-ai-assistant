import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/models/briefing_item.dart';
import 'package:sebastian_app/widgets/routine_controller.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';

class BriefingController extends GetxController {
  final scheduleController = Get.find<ScheduleController>();
  final routineController = Get.find<RoutineController>();

  // RxList<BriefingItem> todayItems =<BriefingItem>[].obs;
  // 오늘 브리핑
  final todayItems = <BriefingItem>[].obs;

  // 완료한 일정
  final completedItems = <BriefingItem>[].obs;

  @override
  void onInit() {
    super.onInit();

    _initBriefing();
  }

  Future<void> _initBriefing() async {
    await scheduleController.fetchTodos();
    await loadTodayBriefing();
  }

  /// 오전/오후 형식
  String formatKoreanTimeAmPm(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');

    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$period $displayHour:$minute';
  }

  Future<void> loadTodayBriefing() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    completedItems.clear();

    List<BriefingItem> result = [];

    await routineController.ensureCompletionsLoaded(today);

    for (var r in routineController.routines) {
      if (!routineController.matchesDate(r, today)) continue;

      if (routineController.isCompletedOnDate(r.id, today)) {

        completedItems.add(
          BriefingItem(
            title: "${r.category} - ${r.title}",
            subTitle: "루틴",
            time: r.targetTime,
            icon: Icons.check_circle,
          ),
        );

        continue;
      }

      String routineTime = r.targetTime;

      if (routineTime.contains(':')) {
        final parts = routineTime.split(':');

        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;

          final dt = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          );

          routineTime = formatKoreanTimeAmPm(dt);
        }
      }

      result.add(
        BriefingItem(
          title: "${r.category} - ${r.title}",
          subTitle: "루틴",
          time: routineTime,
          icon: Icons.favorite_border,
        ),
      );
    }

    // 일정
    final schedules = scheduleController.getSchedules(now);

    for (var s in schedules) {

      if (s.isCompleted) {

        completedItems.add(
          BriefingItem(
            title: s.title,
            subTitle: "일정",
            time: formatKoreanTimeAmPm(s.dateTime),
            icon: Icons.check_circle,
          ),
        );

        continue;
      }

      final isAllDay =
          s.dateTime.hour == 0 && s.dateTime.minute == 0;

      result.add(
        BriefingItem(
          title: s.title,
          subTitle: "일정",
          time: isAllDay
              ? "하루 종일"
              : formatKoreanTimeAmPm(s.dateTime),
          icon: s.icon,
        ),
      );
    }

    // 할 일
    for (final todo in scheduleController.todos) {

      final dateTimeStr = todo['dueDate'];
      if (dateTimeStr == null || dateTimeStr.isEmpty) continue;

      final dueDate = DateTime.parse(dateTimeStr).toLocal();

      if (todo['isDone'] == true) {

        completedItems.add(
          BriefingItem(
            icon: Icons.check_circle,
            title: todo['title'],
            subTitle: 'TO-DO',
            time: formatKoreanTimeAmPm(dueDate),
          ),
        );

        continue;
      }

      final leadDays = todo['scheduleLeadDays'] ?? 0;

      final startDate = dueDate.subtract(Duration(days: leadDays));

      DateTime onlyDate(DateTime d) =>
          DateTime(d.year, d.month, d.day);

      final todayDate = onlyDate(now);
      final start = onlyDate(startDate);
      final end = onlyDate(dueDate);

      if (todayDate.isBefore(start) || todayDate.isAfter(end)) {
        continue;
      }

      result.add(
        BriefingItem(
          icon: Icons.check_box_outlined,
          title: todo['title'],
          subTitle: 'TO-DO',
          time: formatKoreanTimeAmPm(dueDate),
        ),
      );
    }

    // 시간순 정렬
    result.sort((a, b) {
      // 하루 종일은 맨 위로
      if (a.time == '하루 종일') return -1;
      if (b.time == '하루 종일') return 1;

      return a.time.compareTo(b.time);
    });

    todayItems.value = result;
  
    // for (var item in todayItems) {
    //   print("${item.time} | ${item.title} | ${item.subTitle}");
    // }
  }

  List<BriefingItem> get expiredItems {
    final now = DateTime.now();

    return todayItems.where((item) {

      if (item.time == "하루 종일") {
        return false;
      }

      try {

        final isPm = item.time.contains("오후");

        final timePart =
            item.time.replaceAll("오전 ", "")
                    .replaceAll("오후 ", "");

        final parts = timePart.split(":");

        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);

        if (isPm && hour != 12) {
          hour += 12;
        }

        if (!isPm && hour == 12) {
          hour = 0;
        }

        final target = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        return target.isBefore(now);

      } catch (_) {
        return false;
      }
    }).toList();
  }
}