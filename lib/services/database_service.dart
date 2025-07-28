import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import '../database/diary_database.dart';
import '../repository/diary_repository.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DiaryDatabase? _diaryDatabase;
  static DiaryRepository? _diaryRepository;

  DatabaseService._internal();

  static DatabaseService get instance {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  /// 데이터베이스를 초기화합니다.
  Future<void> initialize() async {
    try {
      // 데스크톱 플랫폼에서는 sqflite_common_ffi 초기화 필요
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print('데스크톱 플랫폼: sqflite_common_ffi 초기화 완료');
      }
      
      _diaryDatabase = DiaryDatabase();
      await _diaryDatabase!.initDatabase();
      _diaryRepository = DiaryRepository(_diaryDatabase!);
      print('데이터베이스 초기화 완료');
    } catch (e) {
      print('데이터베이스 초기화 실패: $e');
      rethrow;
    }
  }

  /// 일기 저장소를 반환합니다.
  DiaryRepository get diaryRepository {
    if (_diaryRepository == null) {
      throw Exception('데이터베이스가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.');
    }
    return _diaryRepository!;
  }

  /// 데이터베이스를 닫습니다.
  Future<void> dispose() async {
    try {
      if (_diaryDatabase != null) {
        await _diaryDatabase!.closeDatabase();
        _diaryDatabase = null;
        _diaryRepository = null;
        print('데이터베이스 연결 종료');
      }
    } catch (e) {
      print('데이터베이스 종료 중 오류: $e');
    }
  }

  /// 데이터베이스가 초기화되었는지 확인합니다.
  bool get isInitialized => _diaryDatabase != null && _diaryRepository != null;
} 