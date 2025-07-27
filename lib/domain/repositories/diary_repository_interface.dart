import '../entities/diary_entity.dart';

abstract class IDiaryRepository {
  Future<void> createDiary(DiaryEntity diary);
  Future<void> updateDiary(DiaryEntity diary);
  Future<void> deleteDiary(DateTime date, String userId);
  Future<DiaryEntity?> getDiaryByDate(DateTime date, String userId);
  Future<List<DiaryEntity>> getDiariesByDateRange(
    DateTime startDate,
    DateTime endDate,
    String userId,
  );
  Future<bool> hasDiary(DateTime date, String userId);
  Future<List<DiaryEntity>> getAllDiaries(String userId);
}