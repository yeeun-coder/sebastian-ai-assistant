import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/routes/app_routes.dart';
import 'package:sebastian_app/services/auth_session.dart';
import 'package:sebastian_app/widgets/common/custom_icon.dart';
import 'package:sebastian_app/widgets/ai_controller.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final aiController = Get.find<AIController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
      ),
      body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
        child: Column(
          children: [
            // const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
            const Text(
              "나만의 AI",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Obx(() => GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.aiSetting),
              child: CustomIcon(
                size: 100,
                child: Image.asset(aiController.image.value),
              ),
            )),

            const SizedBox(height: 10),

            Obx(() => Text(
              aiController.name.value,
              style: const TextStyle(fontSize: 20),
            )),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _tile(
                    icon: "🤖",
                    title: 'AI 설정 & 비용',
                    subtitle: 'API 키, 프로바이더, 사용량 확인',
                    onTap: () => Get.toNamed(AppRoutes.aiCost),
                  ),
                  _tile(
                    icon: "👤",
                    title: '프로필 설정',
                    subtitle: '사용자 이름, 나이, 성별 등',
                    onTap: () => Get.toNamed(AppRoutes.userEdit),
                  ),
                  _tile(
                    icon: "🔒",
                    title: '비밀번호 변경',
                    subtitle: '계정 비밀번호 재설정',
                    onTap: _showPasswordChangeDialog,
                  ),
                  const Divider(color: Colors.grey),
                  _tile(
                    icon: "🚪",
                    title: '로그아웃',
                    subtitle: '',
                    color: Colors.red,
                    onTap: _showLogoutDialog,
                  ),
                  _tile(
                    icon: "✂️",
                    title: '계정 삭제',
                    subtitle: '',
                    color: Colors.red,
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required String icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Text(
        icon, 
        style: TextStyle(
          color: color ?? Colors.blueGrey,
          fontSize: 25,
          fontFamily: "Mona12Emoji",
        )
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // 비밀번호 변경 다이얼로그
  void _showPasswordChangeDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("비밀번호 변경"),
        content: const Text("비밀번호를 변경하러 가시겠습니까?(가면 로그아웃 됩니다)"),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.toNamed(AppRoutes.password, arguments: {'loggedIn': true});
            },
            child: const Text(
              "비밀번호 변경",
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("취소"),
          ),
        ],
      ),
    );
  }
  
  // 로그아웃 다이얼로그
  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("로그아웃"),
        content: const Text("로그아웃 하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () async {
              await AuthSession.clearAll();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text(
              "로그아웃",
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("아니요"),
          ),
        ],
      ),
    );
  }

  // 계정 삭제 다이얼로그
  void _showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("계정 삭제"),
        content: const Text("계정을 삭제하시겠습니까?(삭제하면 모든 데이터가 사라집니다)"),
        actions: [
          TextButton(
            onPressed: () async {
              await AuthSession.clearAll();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text(
              "계정 삭제",
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("아니요"),
          ),
        ],
      ),
    );
  }
}