import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// 학교 프로젝트: 로컬에서 Nest를 띄우고 시뮬레이터/에뮬에서 붙을 때 사용.
/// - Android 에뮬레이터: 10.0.2.2 (호스트 PC의 localhost)
/// - iOS 시뮬레이터/데스크톱/웹: localhost
class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}
