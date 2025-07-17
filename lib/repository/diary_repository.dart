import '../database/diary_database.dart';
import '../models/diary_entry.dart';

class DiaryRepository {
  final DiaryDatabase _database;

  DiaryRepository(this._database);

  /// 일기를 저장합니다.
  Future<void> saveDiary(DiaryEntry entry) async {
    await _database.insertDiary(entry);
  }

  /// 모든 일기를 조회합니다.
  Future<List<DiaryEntry>> getAllDiaries() async {
    return await _database.getAllDiaries();
  }

  /// 특정 날짜의 일기를 조회합니다.
  Future<DiaryEntry?> getDiaryByDate(DateTime date) async {
    return await _database.getDiaryByDate(date);
  }

  /// 일기를 업데이트합니다.
  Future<void> updateDiary(DiaryEntry entry) async {
    await _database.updateDiary(entry);
  }

  /// 특정 날짜의 일기를 삭제합니다.
  Future<void> deleteDiary(DateTime date) async {
    await _database.deleteDiary(date);
  }

  /// 날짜 범위로 일기를 조회합니다.
  Future<List<DiaryEntry>> getDiariesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _database.getDiariesByDateRange(startDate, endDate);
  }

  /// 특정 달의 일기를 조회합니다.
  Future<List<DiaryEntry>> getDiariesByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return await _database.getDiariesByDateRange(startDate, endDate);
  }

  /// 해당 날짜에 일기가 존재하는지 확인합니다.
  Future<bool> hasDiaryOnDate(DateTime date) async {
    final diary = await _database.getDiaryByDate(date);
    return diary != null;
  }

  /// 데이터베이스 연결을 닫습니다.
  Future<void> dispose() async {
    await _database.closeDatabase();
  }
} 