import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/screens/splash_screen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Kakao SDK
  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '',
  );

  // Initialize Database Service
  try {
    await DatabaseService.instance.initialize();
    print('앱 시작: 데이터베이스 초기화 성공');
  } catch (e) {
    print('앱 시작: 데이터베이스 초기화 실패 - $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko'), // 한국어
        Locale('en'), // 영어
        Locale('ja'), // 일본어
        Locale('zh'), // 중국어
      ],
      path: 'assets/translations', // 번역 파일 경로
      fallbackLocale: const Locale('ko'), // 기본 언어
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_name'.tr(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
