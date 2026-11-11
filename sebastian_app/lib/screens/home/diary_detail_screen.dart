import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sebastian_app/models/diary_entry.dart';
import 'package:sebastian_app/widgets/diary_controller.dart';

class DiaryDetailScreen extends StatelessWidget {
  const DiaryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final entry = args['entry'] as DiaryEntry;
    final controller = Get.find<DiaryController>();

    String formatDate(String dateString) {
      final date = DateTime.parse(dateString);

      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

      return '${date.year}년 '
          '${date.month}월 '
          '${date.day}일 '
          '(${weekdays[date.weekday - 1]})';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          formatDate(entry.diaryDate),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') {
                Get.toNamed(
                  '/add-diary',
                  arguments: {
                    'diaryDate': entry.diaryDate,
                    'entry': entry,
                  },
                )?.then((_) {
                  Get.back();
                  controller.loadAroundSelectedDate();
                });
              }

              if (value == 'delete') {
                final ok = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('일기 삭제'),
                    content: const Text('이 일기를 삭제할까요?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        child: const Text(
                          '삭제',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (ok == true) {
                  final deleted = await controller.deleteDiary(
                    entry.id,
                    entry.diaryDate,
                  );

                  if (deleted) {
                    Get.back();
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('수정'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '삭제',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   entry.diaryDate,
            //   style: TextStyle(
            //     fontSize: 14,
            //     color: Colors.grey.shade600,
            //   ),
            // ),
            if (entry.mood != null && entry.mood!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: getMoodColor(entry.mood!),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${getMoodEmoji(entry.mood!)} ${entry.mood!}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mona12Emoji',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              entry.displayTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              entry.content,
              style: const TextStyle(fontSize: 17, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

String getMoodEmoji(String mood) {
  switch (mood) {
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

Color getMoodColor(String mood) {
  switch (mood) {
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
