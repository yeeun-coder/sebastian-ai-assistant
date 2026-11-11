import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sebastian_app/models/schedule_item.dart';
import 'package:sebastian_app/widgets/common/custom_button.dart';

/// 일정 시작 N분 전(일정별 [ScheduleItem.notificationLeadMinutes])에, 앱이 **포그라운드**이면 확인 다이얼로그만 띄웁니다.
/// (백그라운드·종료 시에는 [ScheduleNotificationService]의 시스템 알림에 의존합니다.)
class ScheduleDialogScheduler {
  ScheduleDialogScheduler._();
  static final ScheduleDialogScheduler instance = ScheduleDialogScheduler._();

  final List<Timer> _timers = [];

  void sync(List<ScheduleItem> items) {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();

    final now = DateTime.now();

    for (final item in items) {
      if (!item.isAlarmOn) continue;
      final startLocal = item.dateTime.toLocal();
      final fireAt =
          startLocal.subtract(Duration(minutes: item.notificationLeadMinutes));
      if (!fireAt.isAfter(now)) continue;

      final delay = fireAt.difference(now);
      _timers.add(Timer(delay, () => _tryShowDialog(item)));
    }
  }

  void cancelAll() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _tryShowDialog(ScheduleItem item) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = WidgetsBinding.instance.lifecycleState;
      if (state != AppLifecycleState.resumed) {
        return;
      }

      final timeLabel = formatKoreanTimeAmPm(item.dateTime);
      Get.dialog<void>(
        barrierDismissible: false,
        PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text('$timeLabel ${item.title}'),
            content: Text(
              '${item.title} ${item.notificationLeadMinutes}분 전입니다.\n${item.content}',
            ),
            actions: [
              CustomButton(
                variant: CustomButtonVariant.darkLong,
                onPressed: () => Get.back<void>(),
                label: "확인",
              ),
            ],
          ),
        ),
      );
    });
  }
}
