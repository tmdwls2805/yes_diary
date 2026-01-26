import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:yes_diary/database/diary_database.dart';
import 'package:yes_diary/models/diary_entry.dart';

void main() {
  group('DiaryDatabase 테스트', () {
    late DiaryDatabase database;

    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      database = DiaryDatabase();
      await database.initDatabase();
      // 테스트 전에 데이터베이스 초기화
      final db = await database.database;
      await db.delete('diary_entries');
    });

    tearDown(() async {
      await database.closeDatabase();
    });

    test('데이터베이스가 올바르게 초기화되는지 확인', () async {
      // Given & When
      final db = await database.database;

      // Then
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('일기 삽입 테스트', () async {
      // Given
      final entry = DiaryEntry(
        date: DateTime(2024, 1, 1),
        content: '오늘은 좋은 하루였다.',
        emotionId: 5, // green
      );

      // When
      await database.insertDiary(entry);

      // Then
      final entries = await database.getAllDiaries();
      expect(entries.length, equals(1));
      expect(entries.first.content, equals(entry.content));
      expect(entries.first.emotionId, equals(entry.emotionId));
    });

    test('모든 일기 조회 테스트', () async {
      // Given
      final entries = [
        DiaryEntry(
          date: DateTime(2024, 1, 1),
          content: '첫 번째 일기',
          emotionId: 5, // green
        ),
        DiaryEntry(
          date: DateTime(2024, 1, 2),
          content: '두 번째 일기',
          emotionId: 3, // blue
        ),
      ];

      // When
      for (final entry in entries) {
        await database.insertDiary(entry);
      }

      // Then
      final result = await database.getAllDiaries();
      expect(result.length, equals(2));
    });

    test('날짜로 일기 조회 테스트', () async {
      // Given
      final date = DateTime(2024, 1, 1);
      final entry = DiaryEntry(
        date: date,
        content: '특정 날짜 일기',
        emotionId: 1, // red
      );

      // When
      await database.insertDiary(entry);
      final result = await database.getDiaryByDate(date);

      // Then
      expect(result, isNotNull);
      expect(result!.content, equals(entry.content));
      expect(result.emotionId, equals(entry.emotionId));
    });

    test('존재하지 않는 날짜 조회 시 null 반환 테스트', () async {
      // Given
      final date = DateTime(2024, 1, 1);

      // When
      final result = await database.getDiaryByDate(date);

      // Then
      expect(result, isNull);
    });

    test('일기 업데이트 테스트', () async {
      // Given
      final originalEntry = DiaryEntry(
        date: DateTime(2024, 1, 1),
        content: '원래 내용',
        emotionId: 5, // green
      );
      await database.insertDiary(originalEntry);

      final updatedEntry = DiaryEntry(
        date: DateTime(2024, 1, 1),
        content: '업데이트된 내용',
        emotionId: 3, // blue
      );

      // When
      await database.updateDiary(updatedEntry);

      // Then
      final result = await database.getDiaryByDate(DateTime(2024, 1, 1));
      expect(result, isNotNull);
      expect(result!.content, equals('업데이트된 내용'));
      expect(result.emotionId, equals(3)); // blue
    });

    test('일기 삭제 테스트', () async {
      // Given
      final entry = DiaryEntry(
        date: DateTime(2024, 1, 1),
        content: '삭제될 일기',
        emotionId: 1, // red
      );
      await database.insertDiary(entry);

      // When
      await database.deleteDiary(DateTime(2024, 1, 1));

      // Then
      final result = await database.getDiaryByDate(DateTime(2024, 1, 1));
      expect(result, isNull);
    });

    test('날짜 중복 방지 테스트 - 같은 날짜에 두 번 삽입 시 업데이트', () async {
      // Given
      final firstEntry = DiaryEntry(
        date: DateTime(2024, 1, 1),
        content: '첫 번째 일기',
        emotionId: 5, // green
      );
      final secondEntry = DiaryEntry(
        date: DateTime(2024, 1, 1),
        content: '두 번째 일기',
        emotionId: 3, // blue
      );

      // When
      await database.insertDiary(firstEntry);
      await database.insertDiary(secondEntry);

      // Then
      final entries = await database.getAllDiaries();
      expect(entries.length, equals(1));
      expect(entries.first.content, equals('두 번째 일기'));
      expect(entries.first.emotionId, equals(3)); // blue
    });

    test('날짜 범위로 일기 조회 테스트', () async {
      // Given
      final entries = [
        DiaryEntry(
          date: DateTime(2024, 1, 1),
          content: '1월 1일 일기',  
          emotionId: 5, // green
        ),
        DiaryEntry(
          date: DateTime(2024, 1, 5),
          content: '1월 5일 일기',
          emotionId: 3, // blue
        ),
        DiaryEntry(
          date: DateTime(2024, 1, 10),
          content: '1월 10일 일기',
          emotionId: 1, // red
        ),
      ];

      for (final entry in entries) {
        await database.insertDiary(entry);
      }

      // When
      final result = await database.getDiariesByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      );

      // Then
      expect(result.length, equals(2));
      expect(result[0].content, equals('1월 1일 일기'));
      expect(result[1].content, equals('1월 5일 일기'));
    });
  });
} 