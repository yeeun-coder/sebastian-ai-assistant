import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStorage {
  CredentialStorage._();

  static const _storage = FlutterSecureStorage();
  static const _emailKey = 'auto_login_email';
  static const _passwordKey = 'auto_login_password';
  static const _enabledKey = 'auto_login_enabled';

  static Future<bool> isAutoLoginEnabled() async {
    return (await _storage.read(key: _enabledKey)) == '1';
  }

  static Future<void> setAutoLoginEnabled(bool enabled) async {
    await _storage.write(key: _enabledKey, value: enabled ? '1' : '0');
  }

  static Future<void> save(String email, String password) async {
    await setAutoLoginEnabled(true);
    await _storage.write(key: _emailKey, value: email.trim());
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<({String email, String password})?> load() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null ||
        password == null ||
        email.isEmpty ||
        password.isEmpty) {
      return null;
    }
    return (email: email, password: password);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
