import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/common/custom_button.dart';
import 'package:sebastian_app/routes/app_routes.dart';
import 'package:sebastian_app/services/auth_service.dart';
import 'package:sebastian_app/storage/token_storage.dart';
import 'package:sebastian_app/storage/credential_storage.dart';
import 'package:sebastian_app/widgets/common/custom_TextField.dart';
import 'package:sebastian_app/widgets/user_controller.dart';
import 'package:sebastian_app/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _autoLogin = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLoginPrefs();
  }

  Future<void> _loadSavedLoginPrefs() async {
    final enabled = await CredentialStorage.isAutoLoginEnabled();
    final creds = await CredentialStorage.load();
    if (!mounted) return;

    setState(() {
      _autoLogin = enabled && creds != null;
      if (creds != null) {
        emailController.text = creds.email;
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('알림', '이메일과 비밀번호를 입력해 주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(email, password);

      if (result != null) {
        await TokenStorage.saveToken(result['token']);
        if (_autoLogin) {
          await CredentialStorage.save(email, password);
        } else {
          await CredentialStorage.setAutoLoginEnabled(false);
        }

        // 프로필 정보 가져오기
        final userService = UserService();
        final profile = await userService.getProfile();

        if (profile != null) {
          final userController = Get.find<UserController>();
          userController.setUser(
            profile['nickname'] ?? "",
            profile['age'] ?? 0,
            profile['gender'] ?? "",
          );
          userController.setProfileImage(profile['profileImage'] as String?);
        }

        Get.offAllNamed(
          '/briefing',
          arguments: {'fromLogin': true},
        );
        Get.snackbar('로그인', '성공');
      } else {
        Get.snackbar('로그인 실패', '이메일 또는 비밀번호를 확인해 주세요.');
      }
    } catch (_) {
      if (!mounted) return;
      Get.snackbar('오류', '네트워크를 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //final authService = AuthService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              // 상단 로고
              const Image(image: AssetImage("assets/images/logo1.png"), width: 80),
              const Text(
                "나의 세바스찬",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // 로그인 박스
              Container(
                width: 288,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 22,
                      width: double.infinity,
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.only(left: 2, top: 0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFEFEF),
                        border: Border(
                          bottom: BorderSide(color: Colors.black),
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/images/icon.png", 
                            width: 40,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 이메일
                          const Text(
                            "이메일",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CustomTextField(
                            controller: emailController,
                            hintText: 'example@email.com',
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                          ),

                          const SizedBox(height: 20),

                          // 비밀번호
                          const Text(
                            "비밀번호",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CustomTextField(
                            controller: passwordController,
                            hintText: '6자 이상',
                            isPassword: true,
                          ),

                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.scale(
                                    scale: 0.75,
                                    alignment: Alignment.centerLeft,
                                    child: Checkbox(
                                      value: _autoLogin,
                                      onChanged: (value) {
                                        setState(
                                          () => _autoLogin = value ?? false,
                                        );
                                      },
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      side: const BorderSide(
                                        width: 1.2,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _autoLogin = !_autoLogin);
                                    },
                                    child: const Text(
                                      '자동 로그인',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () =>
                                    Get.toNamed(AppRoutes.passwordReset),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  '비밀번호를 잊으셨나요?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // 로그인 버튼
                          Center(
                            child: SizedBox(
                              width: 170,
                              height: 35,
                              child: CustomButton(
                                label: "로그인",
                                onPressed: _login,
                                isLoading: _isLoading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // 회원가입
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("계정이 없으신가요? ",),
                  TextButton(
                    onPressed: () => Get.offAllNamed('/signup'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "회원가입하기",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}