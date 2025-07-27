import '../database/diary_database.dart';
import '../models/diary_entry.dart';

class DiaryRepository {
  final DiaryDatabase _database;

  DiaryRepository(this._database);

  /// 일기를 저장합니다.
  Future<void> insertDiary(DiaryEntry entry) async {
    await _database.insertDiary(entry);
  }

  /// 모든 일기를 조회합니다.
  Future<List<DiaryEntry>> getAllDiaries() async {
    return await _database.getAllDiaries();
  }

  /// 특정 사용자 ID의 모든 일기를 조회합니다.
  Future<List<DiaryEntry>> getAllDiariesByUserId(String userId) async {
    return await _database.getAllDiariesByUserId(userId);
  }

  /// 특정 날짜의 일기를 조회합니다.
  Future<DiaryEntry?> getDiaryByDate(DateTime date) async {
    return await _database.getDiaryByDate(date);
  }

  /// 특정 날짜와 사용자 ID의 일기를 조회합니다.
  Future<DiaryEntry?> getDiaryByDateAndUserId(DateTime date, String userId) async {
    return await _database.getDiaryByDateAndUserId(date, userId);
  }

  /// 일기를 업데이트합니다.
  Future<void> updateDiary(DiaryEntry entry) async {
    await _database.updateDiary(entry);
  }

  /// 특정 날짜의 일기를 삭제합니다.
  Future<void> deleteDiary(DateTime date) async {
    await _database.deleteDiary(date);
  }

  /// 특정 날짜와 사용자 ID의 일기를 삭제합니다.
  Future<void> deleteDiaryByDateAndUserId(DateTime date, String userId) async {
    await _database.deleteDiaryByDateAndUserId(date, userId);
  }

  /// 날짜 범위로 일기를 조회합니다.
  Future<List<DiaryEntry>> getDiariesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _database.getDiariesByDateRange(startDate, endDate);
  }

  /// 특정 사용자 ID와 날짜 범위로 일기를 조회합니다.
  Future<List<DiaryEntry>> getDiariesByDateRangeAndUserId(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    return await _database.getDiariesByDateRangeAndUserId(startDate, endDate, userId);
  }

  /// 특정 달의 일기를 조회합니다.
  Future<List<DiaryEntry>> getDiariesByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return await _database.getDiariesByDateRange(startDate, endDate);
  }

  /// 특정 사용자 ID의 특정 달 일기를 조회합니다.
  Future<List<DiaryEntry>> getDiariesByMonthAndUserId(int year, int month, String userId) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return await _database.getDiariesByDateRangeAndUserId(startDate, endDate, userId);
  }

  /// 해당 날짜에 일기가 존재하는지 확인합니다.
  Future<bool> hasDiaryOnDate(DateTime date) async {
    final diary = await _database.getDiaryByDate(date);
    return diary != null;
  }

  /// 특정 날짜와 사용자 ID로 일기가 존재하는지 확인합니다.
  Future<bool> hasDiaryOnDateAndUserId(DateTime date, String userId) async {
    final diary = await _database.getDiaryByDateAndUserId(date, userId);
    return diary != null;
  }

  /// 데이터베이스 연결을 닫습니다.
  Future<void> dispose() async {
    await _database.closeDatabase();
  }
} 