import 'package:flutter/material.dart';
import 'package:yes_diary/screens/splash_screen.dart';
import 'package:yes_diary/screens/onboarding_screen.dart';
import 'package:yes_diary/screens/main_screen.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database Service
  try {
    await DatabaseService.instance.initialize();
    print('앱 시작: 데이터베이스 초기화 성공');
  } catch (e) {
    print('앱 시작: 데이터베이스 초기화 실패 - $e');
  }

  // Initialize SecureStorageService and manage user ID and created_at
  final secureStorageService = SecureStorageService();
  const uuid = Uuid();
  final now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  String? userId = await secureStorageService.getUserId();
  String? createdAt = await secureStorageService.getCreatedAt();

  if (userId == null) {
    userId = uuid.v4();
    await secureStorageService.saveUserId(userId);
    print('새 사용자 ID 생성 및 저장: $userId');
  } else {
    print('기존 사용자 ID 로드: $userId');
  }

  if (createdAt == null) {
    createdAt = formatter.format(now);
    await secureStorageService.saveCreatedAt(createdAt);
    print('새 createdAt 생성 및 저장: $createdAt');
  } else {
    print('기존 createdAt 로드: $createdAt');
  }

  runApp(const MyApp());
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
      home: MainScreen(),
    );
  }
}
