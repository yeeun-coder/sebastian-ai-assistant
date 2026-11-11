import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/models/routine.dart';
import 'package:sebastian_app/widgets/common/custom_topbar.dart';
import 'package:sebastian_app/widgets/common/custom_tabbar.dart';
import 'package:sebastian_app/widgets/common/expandable_week_month_calendar.dart';
import 'package:sebastian_app/widgets/routine_controller.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final controller = Get.find<RoutineController>();

  String formatKoreanTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];

    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$period $displayHour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-routine'),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, size: 30,),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
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
            const SizedBox(height: 13),
            Obx(
              () {
                controller.selectedDate.value;
                controller.routines.length;
                return ExpandableWeekMonthCalendar(
                  selectedDate: controller.selectedDate.value,
                  horizontalPadding: 16,
                  weekBarStyle: WeekBarStyle.mondayWeek,
                  hasMarker: controller.hasRoutineOnDate,
                  onDateSelected: controller.selectDate,
                );
              },
            ),

            Expanded(
              child: Obx(() {
                // 선택한 날짜 변경 시 목록이 반드시 다시 그려지도록 구독
                controller.selectedDate.value;
                final grouped = controller.grouped;

                if (grouped.isEmpty) {
                  return const Center(
                    child: Text("이 날짜에 표시할 루틴이 없습니다"),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  children: grouped.entries.map((entry) {
                    final category = entry.key;
                    final items = entry.value;
                    final isOpen = controller.openState[category] ?? true;

                    return _buildSection(
                      category,
                      isOpen,
                      () => controller.toggle(category),
                      items.map((r) {
                        return _buildItem(r);
                      }).toList(),
                    );
                  }).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    bool isOpen,
    VoidCallback onTap,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 토글 부분
        if (isOpen) Column(children: items),
      ],
    );
  }

  Widget _buildItem(Routine r) {
    return Dismissible(
      key: Key(r.id.toString()),
      
      // 오른쪽 → 왼쪽
      dismissThresholds: {
        DismissDirection.endToStart: 0.6,
      },

      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      confirmDismiss: (direction) async {
        return await Get.defaultDialog<bool>(
          title: "삭제",
          middleText: "정말 삭제하시겠습니까?",
          textConfirm: "삭제",
          textCancel: "취소",
          confirmTextColor: Colors.white,
          onConfirm: () {
            Get.back(result: true);
          },
          onCancel: () {
            Get.back(result: false);
          },
        );
      },

      onDismissed: (direction) {
        controller.deleteRoutine(r);
      },

      child: GestureDetector(
        onTap: () {
          Get.toNamed('/add-routine', arguments: r);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // 시간
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Text(
                  formatKoreanTime(r.targetTime),
                ),
              ),

              Container(width: 1, height: 40, color: Colors.grey.shade400),

              // 내용
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(r.title),
                ),
              ),

              Container(width: 1, height: 40, color: Colors.grey.shade400),

              // 체크박스
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Checkbox(
                  value: controller.isCompleted(r),
                  onChanged: (val) {
                    controller.toggleCompletion(r);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}