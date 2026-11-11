import 'package:get/get.dart';
import 'package:sebastian_app/routes/app_routes.dart';
import 'package:sebastian_app/storage/token_storage.dart';

/// API가 401을 돌릴 때 서비스에서 던집니다. 컨트롤러에서 잡아 [SessionRedirect.toLogin]을 호출하세요.
class SessionExpiredException implements Exception {
  const SessionExpiredException();
}

/// 여러 API가 동시에 401을 내도 로그인 전환·스낵바가 한 번만 실행되도록 합니다.
class SessionRedirect {
  SessionRedirect._();

  static bool _busy = false;

  static Future<void> toLogin() async {
    if (_busy) return;
    _busy = true;
    try {
      await TokenStorage.clearToken();
      Get.offAllNamed(AppRoutes.login);
      // 저장된 이메일·비밀번호는 유지 → 로그인 화면에서 재시도 가능
      Future.microtask(() {
        Get.snackbar(
          '알림',
          '로그인이 만료되었습니다. 다시 로그인해 주세요.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    } finally {
      Future.delayed(const Duration(milliseconds: 800), () {
        _busy = false;
      });
    }
  }
}
