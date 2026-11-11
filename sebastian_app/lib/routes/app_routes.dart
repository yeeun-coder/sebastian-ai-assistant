import 'package:get/get.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/password_screen.dart';
import '../screens/auth/password_reset_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/notifications_screen.dart';
import '../screens/home/editNotifications_screen.dart';
import '../screens/home/schedule_screen.dart';
import '../screens/home/addSchedule_screen.dart';
import '../screens/home/addTodo_screen.dart';
import '../screens/home/allTodos_screen.dart';
import '../screens/home/routine_screen.dart';
import '../screens/home/addRoutine_screen.dart';
import '../screens/home/usersSetting_screen.dart';
import '../screens/home/userEdit_screen.dart';
import '../screens/home/setting_screen.dart';
import '../screens/home/ai_setting_screen.dart';
import '../screens/home/ai_cost_screen.dart';
import '../screens/home/briefing_screen.dart';
import '../screens/home/dday_screen.dart';
import '../screens/home/diary_screen.dart';
import '../screens/home/add_diary_screen.dart';
import '../screens/home/diary_detail_screen.dart';
import '../models/diary_entry.dart';
import '../widgets/diary_controller.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const password = '/password';
  static const passwordReset = '/password-reset';
  static const notifications = '/notifications';
  static const editnotifications = '/edit-notifications';
  static const schedule = '/schedule';
  static const addschedule = '/add-schedule';
  static const addtodo = '/add-todo';
  static const alltodos = '/all-todos';
  static const routine = '/routine';
  static const addroutine = '/add-routine';
  static const usersSetting = '/users-setting';
  static const userEdit = '/user-edit';
  static const setting = '/setting';
  static const aiSetting = '/ai-setting';
  static const aiCost = '/ai-cost';
  static const briefing = '/briefing';
  static const dday = '/dday';
  static const diary = '/diary';
  static const addDiary = '/add-diary';
  static const diaryDetail = '/diary-detail';

  static final List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: signup,
      page: () => const SignupScreen(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
        name: password,
        page: () => const PasswordScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
      name: passwordReset,
      page: () => const PasswordResetScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
        name: notifications, 
        page: () => const NotificationsScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: editnotifications, 
        page: () => const EditNotificationsScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: schedule, 
        page: () => const ScheduleScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: addschedule, 
        page: () => const AddScheduleScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: addtodo, 
        page: () => const AddTodoScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: alltodos, 
        page: () => const AllTodosScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: routine, 
        page: () => const RoutineScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: addroutine, 
        page: () => const AddRoutineScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: usersSetting, 
        page: () => const UsersSettingScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: userEdit,
        page: () => const UserEditScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: setting, 
        page: () => const SettingScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: aiSetting, 
        page: () => const AISettingScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: aiCost,
        page: () => const AiCostScreen(),
        transition: Transition.rightToLeft,
    ),
    GetPage(
        name: briefing,
        page: () => const BriefingScreen(),
        transition: Transition.rightToLeft,
    ),
    GetPage(
        name: dday,
        page: () => const DDayScreen(),
        transition: Transition.rightToLeft,
    ),
    GetPage(
        name: diary,
        page: () => const DiaryScreen(),
        transition: Transition.fadeIn,
    ),
    GetPage(
        name: addDiary,
        page: () {
          final args = Get.arguments as Map<String, dynamic>? ?? {};
          return AddDiaryScreen(
            diaryDate: args['diaryDate'] as String? ??
                DiaryController.formatYmd(DateTime.now()),
            existing: args['entry'] as DiaryEntry?,
          );
        },
        transition: Transition.rightToLeft,
    ),
    GetPage(
        name: diaryDetail,
        page: () => const DiaryDetailScreen(),
        transition: Transition.rightToLeft,
    ),
  ];
}