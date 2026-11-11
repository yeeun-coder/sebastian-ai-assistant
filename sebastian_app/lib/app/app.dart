import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import 'theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MySebastianApp extends StatelessWidget {
  const MySebastianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: '나의 세바스찬',
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
        getPages: AppRoutes.pages,
        debugShowCheckedModeBanner: false,
        defaultTransition: Transition.fadeIn,
    );
  }
}
