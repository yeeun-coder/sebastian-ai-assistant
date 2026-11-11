import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/common/custom_button.dart';
import 'package:sebastian_app/services/auth_service.dart';
import 'package:sebastian_app/services/auth_session.dart';
import 'package:sebastian_app/widgets/common/custom_TextField.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _firstFieldController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  // 로그인 상태에서 진입하면 true (Get.arguments로 전달)
  late final bool _isLoggedIn;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _isLoggedIn = (args is Map && args['loggedIn'] == true);
  }

  @override
  void dispose() {
    _firstFieldController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final firstField = _firstFieldController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstField.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar('알림', '모든 필드를 입력해 주세요.');
      return;
    }
    if (password.length < 6) {
      Get.snackbar('알림', '비밀번호는 6자 이상이어야 합니다.');
      return;
    }
    if (password != confirmPassword) {
      Get.snackbar('알림', '비밀번호와 비밀번호 확인이 일치하지 않습니다.');
      return;
    }
    if (_isLoggedIn && firstField == password) {
      Get.snackbar('알림', '현재 비밀번호와 새 비밀번호가 같습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? error;

      if (_isLoggedIn) {
        error = await _authService.updatePasswordAuthenticated(firstField, password);
      } else {
        error = await _authService.updatePassword(firstField, password);
      }

      if (error == null) {
        if (_isLoggedIn) {
          await AuthSession.clearAll();
          Get.offAllNamed('/login');
          Get.snackbar('비밀번호 변경', '성공. 다시 로그인해 주세요.');
        } else {
          Get.offAllNamed('/login');
          Get.snackbar('비밀번호 변경', '성공');
        }
      } else {
        Get.snackbar('비밀번호 변경 실패', error);
      }
    } catch (_) {
      if (!mounted) return;
      Get.snackbar('오류', '네트워크를 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
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
                          // 첫 번째 필드: 로그인 상태면 현재 비밀번호, 아니면 이메일
                          Text(
                            _isLoggedIn ? "현재 비밀번호" : "이메일",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CustomTextField(
                            controller: _firstFieldController,
                            hintText: _isLoggedIn ? '현재 비밀번호 입력' : 'example@email.com',
                            isPassword: _isLoggedIn,
                            keyboardType: _isLoggedIn ? TextInputType.text : TextInputType.emailAddress,
                            autocorrect: false,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "새 비밀번호",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CustomTextField(
                            controller: _passwordController,
                            hintText: '6자 이상의 새로운 비밀번호',
                            isPassword: true,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "새 비밀번호 확인",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CustomTextField(
                            controller: _confirmPasswordController,
                            hintText: '새 비밀번호를 다시 입력해 주세요',
                            isPassword: true,
                          ),

                          const SizedBox(height: 20),

                          Center(
                            child: SizedBox(
                              width: 170,
                              height: 35,
                              child: CustomButton(
                                label: "비밀번호 변경",
                                onPressed: _changePassword,
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

              if (!_isLoggedIn)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Get.offAllNamed('/login'),
                      child: const Text(
                        "로그인하기",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.offAllNamed('/signup'),
                      child: const Text(
                        "회원가입하기",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
