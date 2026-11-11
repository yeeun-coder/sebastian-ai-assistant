import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.black87,
      onSurface: Colors.black,
      surface: Colors.white,
      brightness: Brightness.light,
      surfaceTint: Colors.white,
    ),

    fontFamily: 'Mona12',
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    // 로딩 바
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.black,
      circularTrackColor: Colors.black12,
    ),
    // 아이콘 버튼
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: Colors.black,
        highlightColor: Colors.black12,
      ),
    ),
    // 텍스트 버튼
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        splashFactory: InkRipple.splashFactory,
      ),
    ),
    // 커서 & 선택
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.black,
      selectionColor: Colors.black26,
      selectionHandleColor: Colors.black,
    ),
    // 터치 효과
    splashColor: Colors.black12,
    highlightColor: Colors.transparent,
  );

  // 👉 스플래시 전용 배경색 추가
  static const splash = Colors.black;
}