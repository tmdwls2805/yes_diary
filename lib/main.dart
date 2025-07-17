import 'package:flutter/material.dart';
import 'package:yes_diary/screens/splash_screen.dart';
import 'package:yes_diary/screens/onboarding_screen.dart';
import 'package:yes_diary/screens/main_screen.dart';
import 'package:yes_diary/services/database_service.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // 데이터베이스 초기화
  try {
    await DatabaseService.instance.initialize();
    print('앱 시작: 데이터베이스 초기화 성공');
  } catch (e) {
    print('앱 시작: 데이터베이스 초기화 실패 - $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yes Diary',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainScreen(),
      routes: {
        // '/onboarding': (context) => OnboardingScreen(),
        // '/main': (context) => MainScreen(),
      },
    );
  }
}
