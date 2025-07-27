import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/models/diary_model.dart';

class DiaryDatabase {
  static const String _databaseName = 'diary.db';
  static const int _databaseVersion = 3;
  static const String _tableName = 'diary_entries';

  Database? _database;

  /// 데이터베이스 인스턴스를 반환합니다.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDatabase();
    return _database!;
  }

  /// 데이터베이스를 초기화합니다.
  Future<Database> initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade, 
    );
  }

  /// 데이터베이스 테이블을 생성합니다.
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        date TEXT PRIMARY KEY,
        content TEXT NOT NULL CHECK(LENGTH(content) <= 2000),
        emotion TEXT NOT NULL,
        userId TEXT
      );
    ''');
  }

  /// 데이터베이스 업그레이드 로직 (스키마 변경 시 사용)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 버전 1에서 버전 2로 업그레이드: userId 컬럼 추가
      await db.execute('ALTER TABLE $_tableName ADD COLUMN userId TEXT;');
    }
    if (oldVersion < 3) {
      // 버전 2에서 버전 3으로 업그레이드: content 컬럼에 길이 제한 CHECK 제약조건 추가
      await db.execute('''
        CREATE TABLE temp_diary_entries (
            date TEXT PRIMARY KEY,
            content TEXT NOT NULL CHECK(LENGTH(content) <= 2000),
            emotion TEXT NOT NULL,
            userId TEXT
        );
      ''');
      await db.execute('INSERT INTO temp_diary_entries SELECT date, content, emotion, userId FROM $_tableName;');
      await db.execute('DROP TABLE $_tableName;');
      await db.execute('ALTER TABLE temp_diary_entries RENAME TO $_tableName;');
    }
  }

  /// 일기를 데이터베이스에 삽입합니다. 같은 날짜가 존재하면 업데이트합니다.
  Future<void> insertDiary(DiaryModel entry) async {
    final db = await database;
    await db.insert(
      _tableName,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 모든 일기를 조회합니다.
  Future<List<DiaryModel>> getAllDiaries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return DiaryModel.fromMap(maps[i]);
    });
  }

  /// 특정 사용자 ID의 모든 일기를 조회합니다.
  Future<List<DiaryModel>> getAllDiariesByUserId(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return DiaryModel.fromMap(maps[i]);
    });
  }

  /// 특정 날짜의 일기를 조회합니다.
  Future<DiaryModel?> getDiaryByDate(DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date = ?',
      whereArgs: [DateTime(date.year, date.month, date.day).toIso8601String()],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return DiaryModel.fromMap(maps.first);
    }
    return null;
  }

  /// 특정 날짜와 사용자 ID의 일기를 조회합니다.
  Future<DiaryModel?> getDiaryByDateAndUserId(DateTime date, String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date = ? AND userId = ?',
      whereArgs: [DateTime(date.year, date.month, date.day).toIso8601String(), userId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return DiaryModel.fromMap(maps.first);
    }
    return null;
  }

  /// 일기를 업데이트합니다.
  Future<void> updateDiary(DiaryModel entry) async {
    final db = await database;
    await db.update(
      _tableName,
      entry.toMap(),
      where: 'date = ?',
      whereArgs: [DateTime(entry.date.year, entry.date.month, entry.date.day).toIso8601String()],
    );
  }

  /// 특정 날짜의 일기를 삭제합니다.
  Future<void> deleteDiary(DateTime date) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'date = ?',
      whereArgs: [date.toIso8601String()],
    );
  }

  /// 특정 날짜와 사용자 ID의 일기를 삭제합니다.
  Future<void> deleteDiaryByDateAndUserId(DateTime date, String userId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'date = ? AND userId = ?',
      whereArgs: [date.toIso8601String(), userId],
    );
  }

  /// 날짜 범위로 일기를 조회합니다.
  Future<List<DiaryModel>> getDiariesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        DateTime(startDate.year, startDate.month, startDate.day).toIso8601String(),
        DateTime(endDate.year, endDate.month, endDate.day).toIso8601String(),
      ],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) {
      return DiaryModel.fromMap(maps[i]);
    });
  }

  /// 특정 사용자 ID와 날짜 범위로 일기를 조회합니다.
  Future<List<DiaryModel>> getDiariesByDateRangeAndUserId(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date BETWEEN ? AND ? AND userId = ?',
      whereArgs: [
        DateTime(startDate.year, startDate.month, startDate.day).toIso8601String(),
        DateTime(endDate.year, endDate.month, endDate.day).toIso8601String(),
        userId,
      ],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) {
      return DiaryModel.fromMap(maps[i]);
    });
  }

  /// 특정 날짜와 사용자 ID에 일기가 존재하는지 확인합니다.
  Future<bool> hasDiaryOnDateAndUserId(DateTime date, String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date = ? AND userId = ?',
      whereArgs: [DateTime(date.year, date.month, date.day).toIso8601String(), userId],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  /// 데이터베이스 연결을 닫습니다.
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
