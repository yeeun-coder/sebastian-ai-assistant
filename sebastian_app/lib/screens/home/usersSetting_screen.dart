import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/common/custom_topbar.dart';
import 'package:sebastian_app/widgets/common/custom_tabbar.dart';
import 'package:sebastian_app/widgets/user_controller.dart';
import 'package:sebastian_app/services/user_service.dart';
import 'package:sebastian_app/widgets/profile_avatar.dart';

class UsersSettingScreen extends StatefulWidget {
  const UsersSettingScreen({super.key});

  @override
  State<UsersSettingScreen> createState() => _UsersSettingScreenState();
}

class _UsersSettingScreenState extends State<UsersSettingScreen> {
  final userController = Get.find<UserController>();
  final userService = UserService();
  List<String> tags = [];

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    final data = await userService.getProfile();

    if (data != null && mounted) {
      setState(() {
        if (data['tags'] is List) {
          tags = List<String>.from(data['tags']);
        } else {
          tags = [];
        }
      });
      userController.setUser(
        data['nickname'] ?? '',
        data['age'] ?? 0,
        data['gender'] ?? '',
      );
      userController.setProfileImage(data['profileImage'] as String?);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          children: [
            const CustomTopBar(),
            const SizedBox(height: 8),
            const CustomTabBar(),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 40),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Color(0xFFD9D9D9)),
                        ),
                        child: Column(
                          children: [
                            Obx(
                              () => ProfileAvatar(
                                size: 100,
                                imageUrl: userController.profileImage.value,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Obx(
                              () => Text(
                                '${userController.name.value}님',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Obx(
                              () => Text(
                                '${userController.age.value}세 | ${userController.gender.value}',
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFD9D9D9)),
                            const SizedBox(height: 30),
                            const Text(
                              'AI 한마디',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
