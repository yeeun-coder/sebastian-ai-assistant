import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/screens/home/addSchedule_screen.dart';
import 'package:sebastian_app/models/schedule_item.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';

class ScheduleDetailScreen extends StatelessWidget {
  final ScheduleItem schedule;

  const ScheduleDetailScreen({
    super.key,
    required this.schedule,
  });

  String formatDate(DateTime dt) {
    return
        "${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}";
  }

  String formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');

    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return "$period $displayHour:$minute";
  }

  @override
  Widget build(BuildContext context) {

    final startDate = schedule.dateTime;
    final endDate = schedule.endDateTime ?? schedule.dateTime;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "일정 상세",
          style: TextStyle(color: Colors.black),
        ),

        iconTheme:
            const IconThemeData(color: Colors.black),

        actions: [
          IconButton(
            onPressed: () {
              Get.to(
                () => AddScheduleScreen(schedule: schedule),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              schedule.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),

              child: Column(
                children: [

                  _buildInfoRow(
                    Icons.calendar_today,
                    "날짜",
                    formatDate(startDate),
                  ),

                  const SizedBox(height: 18),

                  _buildInfoRow(
                    Icons.access_time,
                    "시작 시간",
                    formatTime(startDate),
                  ),

                  const SizedBox(height: 18),

                  _buildInfoRow(
                    Icons.access_time,
                    "종료 시간",
                    "${formatDate(endDate)} ${formatTime(endDate)}",
                  ),

                  const SizedBox(height: 18),

                  _buildInfoRow(
                    Icons.today,
                    "종일 여부",
                    schedule.isAllDay ? "하루 종일" : "시간 설정",
                  ),

                  const SizedBox(height: 36),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "메모",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      schedule.content.isEmpty
                          ? "내용 없음"
                          : schedule.content,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [

        Icon(icon, size: 20),

        const SizedBox(width: 12),

        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),

        const Spacer(),

        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}