import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/services/auth_service.dart';
import 'package:sebastian_app/widgets/common/custom_button.dart';
import 'package:sebastian_app/widgets/common/custom_TextField.dart';

/// 로그인 화면의 '비밀번호를 잊으셨나요?' 전용 재설정 요청 화면
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final emailController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _submitted = false;

  static final RegExp _emailRegex =
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar('알림', '이메일을 입력해 주세요.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      Get.snackbar('알림', '올바른 이메일 형식이 아닙니다.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final error = await _authService.requestPasswordReset(email);
      if (!mounted) return;
      if (error == null) {
        setState(() => _submitted = true);
      } else {
        Get.snackbar('오류', error);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          '비밀번호 재설정',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Image(
                  image: AssetImage('assets/images/logo1.png'),
                  width: 80,
                ),
                const SizedBox(height: 10),
                const Text(
                  '비밀번호를 잊으셨나요?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        padding: const EdgeInsets.only(left: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFEFEF),
                          border: Border(
                            bottom: BorderSide(color: Colors.black),
                          ),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/icon.png',
                              width: 40,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _submitted
                            ? _buildSubmittedBody()
                            : _buildFormBody(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                if (_submitted)
                  CustomButton(
                    label: '로그인 화면으로',
                    variant: CustomButtonVariant.text,
                    onPressed: () => Get.back(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '가입 시 사용한 이메일을 입력하시면\n관리자에게 비밀번호 초기화 요청이 전달됩니다.',
          style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
        ),
        const SizedBox(height: 16),
        const Text(
          '이메일',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        CustomTextField(
          controller: emailController,
          hintText: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 170,
            height: 35,
            child: CustomButton(
              label: '요청하기',
              onPressed: _submit,
              isLoading: _isLoading,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmittedBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 40, color: Colors.black87),
        const SizedBox(height: 12),
        const Text(
          '요청이 전달되었습니다',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '관리자가 본인 확인 후 비밀번호를 초기화하면\n새 비밀번호로 로그인하실 수 있습니다.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
        ),
      ],
    );
  }
}
