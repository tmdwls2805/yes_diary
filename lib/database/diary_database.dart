import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/diary_entry.dart';

class DiaryDatabase {
  static const String _databaseName = 'diary.db';
  static const int _databaseVersion = 1;
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
    );
  }

  /// 데이터베이스 테이블을 생성합니다.
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        date TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        emotion TEXT NOT NULL
      )
    ''');
  }

  /// 일기를 데이터베이스에 삽입합니다. 같은 날짜가 존재하면 업데이트합니다.
  Future<void> insertDiary(DiaryEntry entry) async {
    final db = await database;
    await db.insert(
      _tableName,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 모든 일기를 조회합니다.
  Future<List<DiaryEntry>> getAllDiaries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return DiaryEntry.fromMap(maps[i]);
    });
  }

  /// 특정 날짜의 일기를 조회합니다.
  Future<DiaryEntry?> getDiaryByDate(DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date = ?',
      whereArgs: [date.toIso8601String()],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return DiaryEntry.fromMap(maps.first);
    }
    return null;
  }

  /// 일기를 업데이트합니다.
  Future<void> updateDiary(DiaryEntry entry) async {
    final db = await database;
    await db.update(
      _tableName,
      entry.toMap(),
      where: 'date = ?',
      whereArgs: [entry.date.toIso8601String()],
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

  /// 날짜 범위로 일기를 조회합니다.
  Future<List<DiaryEntry>> getDiariesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) {
      return DiaryEntry.fromMap(maps[i]);
    });
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