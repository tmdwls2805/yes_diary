import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/widgets/app_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database Service
  try {
    await DatabaseService.instance.initialize();
    print('앱 시작: 데이터베이스 초기화 성공');
  } catch (e) {
    print('앱 시작: 데이터베이스 초기화 실패 - $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yes Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AppWrapper(),
    );
  }
}
