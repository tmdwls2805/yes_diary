import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:yes_diary/core/services/widget/widget_sync_service.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/screens/splash_screen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();
  await MobileAds.instance.initialize();

  await SecureStorageService().resetIfFreshInstall();

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId(WidgetSyncService.appGroupId);
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
  }

  Future<void> _handleWidgetLaunch(Uri? uri) async {
    if (uri == null) return;
    if (uri.host == 'offwork' || uri.path.contains('offwork')) {
      await WidgetSyncService.markOffWorkToday();
    }
  }

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
