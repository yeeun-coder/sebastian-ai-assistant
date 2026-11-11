import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/common/custom_topbar.dart';
import 'package:sebastian_app/widgets/common/custom_tabbar.dart';
import 'package:sebastian_app/widgets/common/custom_calendar.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';
import 'package:sebastian_app/widgets/todo_bottomSheet.dart';
import 'package:sebastian_app/screens/home/scheduleDetail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late ScheduleController controller;

  // 중요! 일정만 보기 토글
  bool _importantOnly = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ScheduleController>();
    _loadData();
  }

  Future<void> _loadData() async {
    await controller.loadSchedulesFromDB();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
      padding: const EdgeInsets.only(top: 50),
        child: Stack(
          children: [
            Column(
              children: [
                const CustomTopBar(),
                const SizedBox(height: 8),
                const CustomTabBar(),
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFD9D9D9),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        CustomCalendar(controller: controller),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 2),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "📆",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: "Mona12Emoji",
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Obx(() => Text(
                                        controller.selectedTitle(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )),
                                      const SizedBox(width: 8),
                                      _buildImportantToggle(),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => Get.toNamed('/add-schedule'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      "+",
                                      style: TextStyle(
                                        color: Color(0xFF49454F),
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        height: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(thickness: 1, color: Color(0xFFD9D9D9)),

                              Obx(() => _buildSimpleScheduleList()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 180), 
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: TodoBottomsheet(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantToggle() {
    final active = _importantOnly;
    return InkWell(
      onTap: () => setState(() => _importantOnly = !_importantOnly),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? Colors.amber.shade700 : Colors.white,
          border: Border.all(
            color: active ? Colors.amber.shade700 : Colors.black54,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 14,
              color: active ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 2),
            Text(
              '중요!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleScheduleList() {
    final selectedDay = controller.selectedDay.value;
    final all = controller.getSchedules(selectedDay);
    final items = _importantOnly
        ? all.where((e) => e.isImportant).toList()
        : all;

    if (items.isEmpty) {
      final isToday = controller.isSameDay(selectedDay, DateTime.now());
      String emptyText;
      if (_importantOnly) {
        emptyText = isToday
            ? "오늘 중요 일정이 없습니다"
            : "${selectedDay.month}월 ${selectedDay.day}일 중요 일정이 없습니다";
      } else {
        emptyText = isToday
            ? "오늘 일정이 없습니다"
            : "${selectedDay.month}월 ${selectedDay.day}일 일정이 없습니다";
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final done = item.isCompleted;
        final textStyle = TextStyle(
          fontSize: 16,
          color: done ? const Color(0xFFD9D9D9) : Colors.black87,
          decoration: done ? TextDecoration.lineThrough : null,
        );
        final timeStyle = TextStyle(
          fontSize: 16,
          color: done ? const Color(0xFFD9D9D9) : Colors.black54,
          decoration: done ? TextDecoration.lineThrough : null,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Get.to(() => ScheduleDetailScreen(schedule: item));
                  },
                  onLongPress: () => _showDeleteDialog(context, item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: done
                                    ? const Color(0xFFD9D9D9)
                                    : Colors.black87,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  item.title,
                                  style: textStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.isImportant) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: done
                                      ? const Color(0xFFD9D9D9)
                                      : Colors.amber.shade700,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            item.dateTime.hour == 0 && item.dateTime.minute == 0
                                ? '하루 종일'
                                : formatKoreanTimeAmPm(item.dateTime),
                            style: timeStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Checkbox(
                  value: done,
                  onChanged: (_) => controller.toggleScheduleCompleted(item),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 삭제 확인
  void _showDeleteDialog(BuildContext context, dynamic item) {
    Get.dialog(
      AlertDialog(
        title: const Text("일정 삭제"),
        content: Text("'${item.title}' 일정을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () {
              controller.deleteSchedule(item.id, item.dateTime); 
              Get.back();
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("취소"),
          ),
        ],
      ),
    );
  }
}