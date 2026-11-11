import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/routes/app_routes.dart';
import 'package:sebastian_app/services/auth_service.dart';
import 'package:sebastian_app/widgets/common/custom_button.dart';
import 'package:sebastian_app/widgets/common/custom_TextField.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
  
  
  final authService = AuthService();

  DateTime _birthDate = DateTime.now();
  /// 서버 DTO: '남' | '여'
  String _gender = '여';

  bool _isLoading = false;

  Widget _buildDropdown(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        height: 25,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: const TextStyle(fontSize: 13)),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('ko', 'KR'),
          child: Theme(
            data: Theme.of(context).copyWith(
              dialogTheme: const DialogThemeData(
                backgroundColor: Colors.white,
              ),
              colorScheme: const ColorScheme.light(
                primary: Colors.black,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Widget _genderChoice(String apiValue, String label) {
    final selected = _gender == apiValue;
    return InkWell(
      onTap: () => setState(() => _gender = apiValue),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: selected ? const Color(0xFF333333) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _formatBirthDate() {
    final y = _birthDate.year.toString().padLeft(4, '0');
    final m = _birthDate.month.toString().padLeft(2, '0');
    final d = _birthDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;
    final nickname = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty || nickname.isEmpty) {
      Get.snackbar('알림', '필수 항목을 모두 입력해 주세요.');
      return;
    }
    if (password.length < 6) {
      Get.snackbar('알림', '비밀번호는 6자 이상이어야 합니다.');
      return;
    }
    if (password != confirm) {
      Get.snackbar('알림', '비밀번호가 일치하지 않습니다.');
      return;
    }
    if (nickname.length < 2) {
      Get.snackbar('알림', '이름(닉네임)은 2자 이상 입력해 주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final errorMessage = await authService.signup(
        email: email,
        password: password,
        nickname: nickname,
        birthDate: _formatBirthDate(),
        gender: _gender,
      );
      if (!mounted) return;

      if (errorMessage == null) {
        Get.snackbar('회원가입', '가입이 완료되었습니다.');
        Get.offAllNamed(AppRoutes.login);
      } else {
        Get.snackbar('회원가입 실패', errorMessage);
      }
    } catch (_) {
      if (mounted) {
        Get.snackbar('오류', '네트워크를 확인해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
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

              const SizedBox(height: 20),

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

                          const SizedBox(height: 20),

                          const Text(
                            "비밀번호 확인",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CustomTextField(
                            controller: confirmPasswordController,
                            hintText: '비밀번호를 다시 입력하세요',
                            isPassword: true,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "이름",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CustomTextField(
                            controller: nameController,
                            hintText: '엄마 저 힘낼게요',
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "생년월일",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickBirthDate,
                            child: Row(
                              children: [
                                _buildDropdown('${_birthDate.year}년'),
                                const SizedBox(width: 5),
                                _buildDropdown('${_birthDate.month}월'),
                                const SizedBox(width: 5),
                                _buildDropdown('${_birthDate.day}일'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "성별",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _genderChoice('남', '남자'),
                              _genderChoice('여', '여자'),
                            ],
                          ),

                          const SizedBox(height: 25),

                          CustomButton(
                            label: '회원가입',
                            onPressed: _signup,
                            isLoading: _isLoading,
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
                  const Text("계정이 있으신가요? "),
                  TextButton(
                    onPressed: () => Get.offAllNamed(AppRoutes.login),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "로그인하기",
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
