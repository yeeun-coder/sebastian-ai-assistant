import 'package:get/get.dart';
import 'package:sebastian_app/services/auth_service.dart';
import 'package:sebastian_app/services/user_service.dart';
import 'package:sebastian_app/storage/credential_storage.dart';
import 'package:sebastian_app/storage/token_storage.dart';
import 'package:sebastian_app/widgets/user_controller.dart';

/// 앱 시작 시 토큰·저장된 계정으로 세션 복구
class AuthSession {
  AuthSession._();

  static Future<bool> tryRestore() async {
    if (await _restoreWithToken()) return true;
    return _restoreWithSavedCredentials();
  }

  static Future<bool> _restoreWithToken() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return false;

    final profile = await UserService().getProfile();
    if (profile == null) {
      await TokenStorage.clearToken();
      return false;
    }

    _applyProfile(profile);
    return true;
  }

  static Future<bool> _restoreWithSavedCredentials() async {
    if (!await CredentialStorage.isAutoLoginEnabled()) return false;

    final creds = await CredentialStorage.load();
    if (creds == null) return false;

    try {
      final result = await AuthService().login(creds.email, creds.password);
      if (result == null) {
        await CredentialStorage.clear();
        await TokenStorage.clearToken();
        return false;
      }

      await TokenStorage.saveToken(result['token']);
      await CredentialStorage.save(creds.email, creds.password);

      final profile = await UserService().getProfile();
      if (profile != null) {
        _applyProfile(profile);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static void _applyProfile(Map<String, dynamic> profile) {
    final userController = Get.find<UserController>();
    userController.setUser(
      profile['nickname'] ?? '',
      profile['age'] ?? 0,
      profile['gender'] ?? '',
    );
    userController.setProfileImage(profile['profileImage'] as String?);
  }

  /// 로그아웃·탈퇴 시 토큰과 저장된 로그인 정보 삭제
  static Future<void> clearAll() async {
    await TokenStorage.clearToken();
    await CredentialStorage.clear();
  }
}
