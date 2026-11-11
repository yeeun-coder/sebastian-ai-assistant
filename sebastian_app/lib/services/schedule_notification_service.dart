import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:sebastian_app/models/schedule_item.dart';

/// 일정별 [ScheduleItem.notificationLeadMinutes]분 전 로컬 알림 예약·해제.
class ScheduleNotificationService {
  ScheduleNotificationService._();
  static final ScheduleNotificationService instance =
      ScheduleNotificationService._();

  static const _prefsTrackedIdsKey = 'sn_tracked_schedule_ids';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  int _notificationId(String scheduleId) {
    final h = scheduleId.hashCode & 0x7fffffff;
    return h == 0 ? 1 : h;
  }

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  Future<void> cancelForScheduleId(String scheduleId) async {
    await _plugin.cancel(_notificationId(scheduleId));
  }

  /// 메모리에 올라간 전체 일정으로 예약을 다시 맞춥니다. (삭제·끔 처리 포함)
  Future<void> syncScheduleItems(List<ScheduleItem> items) async {
    if (!_initialized) {
      await init();
    }

    final prefs = await SharedPreferences.getInstance();
    final prevTracked = prefs.getStringList(_prefsTrackedIdsKey) ?? [];
    final currentIds = items.map((e) => e.id).toSet();

    for (final id in prevTracked) {
      if (!currentIds.contains(id)) {
        await cancelForScheduleId(id);
      }
    }

    final now = DateTime.now();

    const androidDetails = AndroidNotificationDetails(
      'schedule_reminders',
      '일정 알림',
      channelDescription: '일정 시작 전 미리 알림',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    for (final item in items) {
      final nid = _notificationId(item.id);

      if (!item.isAlarmOn) {
        await _plugin.cancel(nid);
        continue;
      }

      final startLocal = item.dateTime.toLocal();
      final leadMin = item.notificationLeadMinutes;
      final reminder = startLocal.subtract(Duration(minutes: leadMin));

      if (!reminder.isAfter(now)) {
        await _plugin.cancel(nid);
        continue;
      }

      final when = tz.TZDateTime(
        tz.local,
        reminder.year,
        reminder.month,
        reminder.day,
        reminder.hour,
        reminder.minute,
        reminder.second,
      );

      final timeLabel = formatKoreanTimeAmPm(startLocal);
      final title = item.title;
      final body = '$title 일정이 $timeLabel에 시작합니다. ($leadMin분 전)';

      try {
        await _plugin.zonedSchedule(
          nid,
          title,
          body,
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: item.id,
        );
      } catch (e, st) {
        debugPrint('ScheduleNotificationService exact schedule failed: $e $st');
        try {
          await _plugin.zonedSchedule(
            nid,
            title,
            body,
            when,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: item.id,
          );
        } catch (e2, st2) {
          debugPrint('ScheduleNotificationService inexact schedule failed: $e2 $st2');
        }
      }
    }

    await prefs.setStringList(
      _prefsTrackedIdsKey,
      items.map((e) => e.id).toList(),
    );
  }
}
