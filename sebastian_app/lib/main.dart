import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/app/app.dart';
import 'package:sebastian_app/services/schedule_notification_service.dart';
import 'widgets/schedule_controller.dart';
import 'widgets/ai_controller.dart';
import 'widgets/user_controller.dart';
import 'widgets/routine_controller.dart';
import 'widgets/overdue_chat_controller.dart';
import 'widgets/diary_controller.dart';

/// 작업 전환·탭 제목 등에 쓰이는 앱 표시 이름
//const String kAppName = '나의 세바스찬';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScheduleNotificationService.instance.init();
  // 로그인 전에는 첫 find 때만 생성. fenix로 탭 전환 후에도 재생성 가능.
  Get.lazyPut<ScheduleController>(() => ScheduleController(), fenix: true);
  Get.lazyPut<AIController>(() => AIController(), fenix: true);
  Get.lazyPut<UserController>(() => UserController(), fenix: true);
  Get.lazyPut<RoutineController>(() => RoutineController(), fenix: true);
  // permanent: 앱 세션 내내 인스턴스를 유지 → _sessionChecked 플래그가 리셋되지 않음
  Get.put<OverdueChatController>(OverdueChatController(), permanent: true);
  Get.lazyPut<DiaryController>(() => DiaryController(), fenix: true);
  runApp(const MySebastianApp());
}