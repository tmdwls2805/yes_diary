import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';

class DiaryDatabase {
  static const String _databaseName = 'diary_v4.db';  // 새 DB 파일 사용
  static const int _databaseVersion = 5;  // 버전 5로 업데이트 (새 필드 추가)
  static const String _tableName = 'diary_entries';
  static const String _emotionsTableName = 'emotions';

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
    // 1. emotions 테이블 생성 (먼저 생성해야 함 - Foreign Key 참조를 위해)
    await db.execute('''
      CREATE TABLE $_emotionsTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        imageUrl TEXT
      );
    ''');

    // 2. 기본 감정 데이터 삽입 (ID 순서 고정 - 백엔드와 동일하게)
    // 항상 이 순서대로 생성됩니다
    final emotions = [
      {'id': 1, 'name': 'red', 'imageUrl': 'assets/emotion/red.svg'},
      {'id': 2, 'name': 'yellow', 'imageUrl': 'assets/emotion/yellow.svg'},
      {'id': 3, 'name': 'blue', 'imageUrl': 'assets/emotion/blue.svg'},
      {'id': 4, 'name': 'pink', 'imageUrl': 'assets/emotion/pink.svg'},
      {'id': 5, 'name': 'green', 'imageUrl': 'assets/emotion/green.svg'},
    ];

    for (var emotion in emotions) {
      await db.insert(_emotionsTableName, emotion);
    }

    // 3. diary_entries 테이블 생성 (emotions 테이블 이후에 생성)
    await db.execute('''
      CREATE TABLE $_tableName (
        date TEXT PRIMARY KEY,
        content TEXT NOT NULL CHECK(LENGTH(content) <= 2000),
        emotion_id INTEGER NOT NULL,
        userId TEXT,
        title TEXT,
        serverId INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        FOREIGN KEY (emotion_id) REFERENCES $_emotionsTableName(id)
      );
    ''');
  }

  /// 데이터베이스 업그레이드 로직 (스키마 변경 시 사용)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 버전 1에서 버전 2로 업그레이드: userId 컬럼 추가
      try {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN userId TEXT;');
      } catch (e) {
        // 이미 컬럼이 존재하면 무시
        print('userId column already exists, skipping: $e');
      }
    }
    if (oldVersion < 3) {
      // 버전 2에서 버전 3으로 업그레이드: content 컬럼에 길이 제한 CHECK 제약조건 추가
      try {
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
      } catch (e) {
        print('Version 3 migration already applied or column structure changed, skipping: $e');
      }
    }
    if (oldVersion < 4) {
      // 버전 3에서 버전 4로 업그레이드: emotions 테이블 추가 및 emotion TEXT를 emotion_id INTEGER로 변경

      // 1. emotions 테이블 생성
      try {
        await db.execute('''
          CREATE TABLE emotions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            imageUrl TEXT
          );
        ''');
      } catch (e) {
        print('emotions table already exists, skipping creation: $e');
      }

      // 2. 기본 감정 데이터 삽입 (순서 고정)
      try {
        final emotions = [
          {'id': 1, 'name': 'red', 'imageUrl': 'assets/emotion/red.svg'},
          {'id': 2, 'name': 'yellow', 'imageUrl': 'assets/emotion/yellow.svg'},
          {'id': 3, 'name': 'blue', 'imageUrl': 'assets/emotion/blue.svg'},
          {'id': 4, 'name': 'pink', 'imageUrl': 'assets/emotion/pink.svg'},
          {'id': 5, 'name': 'green', 'imageUrl': 'assets/emotion/green.svg'},
        ];

        for (var emotion in emotions) {
          await db.insert('emotions', emotion, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      } catch (e) {
        print('emotions data already exists, skipping insertion: $e');
      }

      // 3. 기존 데이터를 임시 테이블로 백업하며 emotion TEXT를 emotion_id INTEGER로 변환
      await db.execute('''
        CREATE TABLE temp_diary_entries (
          date TEXT,
          content TEXT,
          emotion_id INTEGER,
          userId TEXT
        );
      ''');

      // 4. 기존 데이터 조회
      final existingDiaries = await db.query('diary_entries');

      // 5. emotion 문자열을 emotion_id로 변환하여 삽입
      for (var diary in existingDiaries) {
        try {
          // emotion 값을 안전하게 가져오기
          final emotionValue = diary['emotion'];
          String emotionName = 'red'; // 기본값

          if (emotionValue != null && emotionValue is String) {
            emotionName = emotionValue;
          }

          // emotion 이름으로 ID 조회
          final emotionResult = await db.query(
            'emotions',
            where: 'name = ?',
            whereArgs: [emotionName],
            limit: 1,
          );

          // emotion_id 결정 (매칭되는 감정이 없으면 기본값 1 사용)
          final emotionId = emotionResult.isNotEmpty
              ? emotionResult.first['id'] as int
              : 1;

          await db.insert('temp_diary_entries', {
            'date': diary['date'],
            'content': diary['content'],
            'emotion_id': emotionId,
            'userId': diary['userId'],
          });
        } catch (e) {
          // 개별 항목 변환 실패 시 건너뛰기
          print('Failed to migrate diary entry: $e');
          continue;
        }
      }

      // 6. 기존 테이블 삭제
      await db.execute('DROP TABLE diary_entries;');

      // 7. 새로운 스키마로 테이블 재생성
      await db.execute('''
        CREATE TABLE diary_entries (
          date TEXT PRIMARY KEY,
          content TEXT NOT NULL CHECK(LENGTH(content) <= 2000),
          emotion_id INTEGER NOT NULL,
          userId TEXT,
          FOREIGN KEY (emotion_id) REFERENCES emotions(id)
        );
      ''');

      // 8. 임시 테이블에서 데이터 복원
      await db.execute('INSERT INTO diary_entries SELECT date, content, emotion_id, userId FROM temp_diary_entries;');

      // 9. 임시 테이블 삭제
      await db.execute('DROP TABLE temp_diary_entries;');
    }

    // 버전 5: title, serverId, createdAt, updatedAt 컬럼 추가
    if (oldVersion < 5) {
      final now = DateTime.now().toIso8601String();

      // title 컬럼 추가
      try {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN title TEXT;');
      } catch (e) {
        print('title column already exists, skipping: $e');
      }

      // serverId 컬럼 추가 (서버 ID 저장용)
      try {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN serverId INTEGER;');
      } catch (e) {
        print('serverId column already exists, skipping: $e');
      }

      // createdAt 컬럼 추가 (기존 데이터는 현재 시간으로)
      try {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN createdAt TEXT;');
        await db.execute('UPDATE $_tableName SET createdAt = ? WHERE createdAt IS NULL;', [now]);
      } catch (e) {
        print('createdAt column already exists, skipping: $e');
      }

      // updatedAt 컬럼 추가 (기존 데이터는 현재 시간으로)
      try {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN updatedAt TEXT;');
        await db.execute('UPDATE $_tableName SET updatedAt = ? WHERE updatedAt IS NULL;', [now]);
      } catch (e) {
        print('updatedAt column already exists, skipping: $e');
      }
    }
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

  /// 특정 사용자 ID의 모든 일기를 조회합니다.
  Future<List<DiaryEntry>> getAllDiariesByUserId(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'userId = ?',
      whereArgs: [userId],
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
      whereArgs: [DateTime(date.year, date.month, date.day).toIso8601String()],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return DiaryEntry.fromMap(maps.first);
    }
    return null;
  }

  /// 특정 날짜와 사용자 ID의 일기를 조회합니다.
  Future<DiaryEntry?> getDiaryByDateAndUserId(DateTime date, String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date = ? AND userId = ?',
      whereArgs: [DateTime(date.year, date.month, date.day).toIso8601String(), userId],
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
  Future<List<DiaryEntry>> getDiariesByDateRange(
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
      return DiaryEntry.fromMap(maps[i]);
    });
  }

  /// 특정 사용자 ID와 날짜 범위로 일기를 조회합니다.
  Future<List<DiaryEntry>> getDiariesByDateRangeAndUserId(
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
      return DiaryEntry.fromMap(maps[i]);
    });
  }

  /// 모든 감정을 조회합니다.
  Future<List<Emotion>> getAllEmotions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _emotionsTableName,
      orderBy: 'id ASC',
    );

    return List.generate(maps.length, (i) {
      return Emotion.fromMap(maps[i]);
    });
  }

  /// 특정 ID의 감정을 조회합니다.
  Future<Emotion?> getEmotionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _emotionsTableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Emotion.fromMap(maps.first);
    }
    return null;
  }

  /// 특정 이름의 감정을 조회합니다.
  Future<Emotion?> getEmotionByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _emotionsTableName,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Emotion.fromMap(maps.first);
    }
    return null;
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
