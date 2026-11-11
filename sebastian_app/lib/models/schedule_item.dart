import 'package:flutter/material.dart';
import 'package:sebastian_app/constants/schedule_notification_constants.dart';

/// 저장된 [DateTime](UTC/로컬)을 한국 로컬 시각으로 바꿔 오전/오후 라벨로 표시합니다.
String formatKoreanTimeAmPm(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour;
  final m = local.minute.toString().padLeft(2, '0');

  final period = h < 12 ? '오전' : '오후';
  final displayHour = h % 12 == 0 ? 12 : h % 12;

  return '$period $displayHour:$m';
}

String formatKoreanTimeRange(DateTime start, DateTime end) {
  return '${formatKoreanTimeAmPm(start)} ~ ${formatKoreanTimeAmPm(end)}';
}

class ScheduleItem {
  final String id;
  final String title;
  final DateTime dateTime;
  final DateTime? endDateTime;
  final IconData icon;
  final String content;
  final bool isAlarmOn;
  final bool isAllDay;
  final bool isImportant;
  final bool isCompleted;
  /// 일정 시작 몇 분 전에 알림할지(로컬 오버라이드·알림 예약에 사용).
  final int notificationLeadMinutes;
  final bool createDday;
  final String? ddayBasis;

  const ScheduleItem({
    required this.id,
    required this.title,
    required this.dateTime,
    this.endDateTime,
    required this.icon,
    required this.content,
    this.isAlarmOn = true,
    this.isAllDay = false,
    this.isImportant = false,
    this.isCompleted = false,
    this.notificationLeadMinutes = kDefaultScheduleNotificationLeadMinutes,
    this.createDday = false,
    this.ddayBasis,
  });

  ScheduleItem copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    DateTime? endDateTime,
    IconData? icon,
    String? content,
    bool? isAlarmOn,
    bool? isAllDay,
    bool? isImportant,
    bool? isCompleted,
    int? notificationLeadMinutes,
    bool? createDday,
    String? ddayBasis,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      icon: icon ?? this.icon,
      content: content ?? this.content,
      isAlarmOn: isAlarmOn ?? this.isAlarmOn,
      isAllDay: isAllDay ?? this.isAllDay,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationLeadMinutes:
          notificationLeadMinutes ?? this.notificationLeadMinutes,
      createDday: createDday ?? this.createDday,
      ddayBasis: ddayBasis ?? this.ddayBasis,
    );
  }

  DateTime get dateOnly =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);
}
