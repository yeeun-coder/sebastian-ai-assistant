import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/constants/schedule_notification_constants.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';

/// 새 일정·일정별 저장이 없을 때 쓰는 **기본** “몇 분 전” (전역).
class EditNotificationsScreen extends StatelessWidget {
  const EditNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 시간 설정'),
      ),
      body: ListView.builder(
        itemCount: kScheduleLeadMinuteOptions.length,
        itemBuilder: (context, index) {
          final minutes = kScheduleLeadMinuteOptions[index];

          return ListTile(
            leading: Radio<int>(
              value: minutes,
              groupValue: kScheduleNotificationLeadMinutes,
              onChanged: (value) async {
                if (value == null) return;
                kScheduleNotificationLeadMinutes = value;
                await Get.find<ScheduleController>().loadSchedulesFromDB();
                if (context.mounted) Get.back<void>();
              },
            ),
            title: Text(formatScheduleLeadLabel(minutes)),
            onTap: () async {
              kScheduleNotificationLeadMinutes = minutes;
              await Get.find<ScheduleController>().loadSchedulesFromDB();
              if (context.mounted) Get.back<void>();
            },
          );
        },
      ),
    );
  }
}
