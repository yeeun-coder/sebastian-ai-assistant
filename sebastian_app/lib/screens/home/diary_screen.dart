import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/models/diary_entry.dart';
import 'package:sebastian_app/widgets/common/custom_topbar.dart';
import 'package:sebastian_app/widgets/common/custom_tabbar.dart';
import 'package:sebastian_app/widgets/common/expandable_week_month_calendar.dart';
import 'package:sebastian_app/widgets/diary_controller.dart';

double _diaryHorizontalPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.08).clamp(16.0, 60.0);
}

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final controller = Get.find<DiaryController>();

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _diaryHorizontalPadding(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(
            '/add-diary',
            arguments: {
              'diaryDate': DiaryController.formatYmd(controller.selectedDate.value),
            },
          )?.then((_) => controller.loadAroundSelectedDate());
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.edit, size: 28, color: Colors.white,),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          children: [
            const CustomTopBar(),
            const SizedBox(height: 8),
            const CustomTabBar(),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFD9D9D9),
              ),
            ),
            const SizedBox(height: 13),
            Obx(
              () {
                controller.selectedDate.value;
                controller.entriesByDate.length;
                return ExpandableWeekMonthCalendar(
                  selectedDate: controller.selectedDate.value,
                  horizontalPadding: 16,
                  weekBarStyle: WeekBarStyle.mondayWeek,
                  hasMarker: controller.hasEntry,
                  onDateSelected: controller.selectDate,
                  onVisibleMonthChanged: controller.loadForMonth,
                );
              },
            ),
            const SizedBox(height: 13),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFD9D9D9),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = controller.entriesFor(controller.selectedDate.value);
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '이 날짜의 일기가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '아래 버튼으로 작성해 보세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    100,
                  ),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = entries[index];

                    return _DiaryContentCard(
                      entry: entry,
                      onTap: () {
                        Get.toNamed(
                          '/diary-detail',
                          arguments: {'entry': entry},
                        )?.then((_) => controller.loadAroundSelectedDate());
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

}

class _DiaryContentCard extends StatelessWidget {
  const _DiaryContentCard({
    required this.entry,
    required this.onTap,
  });

  final DiaryEntry entry;
  final VoidCallback onTap;

  String get moodEmoji {
    switch (entry.mood) {
      case '좋음':
        return '😊';
      case '보통':
        return '😐';
      case '나쁨':
        return '😞';
      default:
        return '📝';
    }
  }

  Color get moodColor {
    switch (entry.mood) {
      case '좋음':
        return const Color(0xFFFFF3CD);
      case '보통':
        return const Color(0xFFE3F2FD);
      case '나쁨':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 감정 태그
                if (entry.mood != null && entry.mood!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: moodColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$moodEmoji ${entry.mood}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mona12Emoji',
                      ),
                    ),
                  ),
                // 시간
                if (entry.displayTime.isNotEmpty)
                  Text(
                    entry.displayTime,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // 제목
            Text(
              entry.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 6),

            // 내용
            Text(
              entry.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 16),

            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 12),

            // 전체보기
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '전체 보기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}