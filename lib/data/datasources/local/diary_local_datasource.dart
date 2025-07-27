import '../../models/diary_model.dart';
import '../../../database/diary_database.dart';

abstract class DiaryLocalDataSource {
  Future<void> insertDiary(DiaryModel diary);
  Future<void> updateDiary(DiaryModel diary);
  Future<void> deleteDiary(DateTime date, String userId);
  Future<DiaryModel?> getDiaryByDate(DateTime date, String userId);
  Future<List<DiaryModel>> getDiariesByDateRange(
    DateTime startDate,
    DateTime endDate,
    String userId,
  );
  Future<bool> hasDiary(DateTime date, String userId);
  Future<List<DiaryModel>> getAllDiaries(String userId);
}

class DiaryLocalDataSourceImpl implements DiaryLocalDataSource {
  final DiaryDatabase _database;

  DiaryLocalDataSourceImpl(this._database);

  @override
  Future<void> insertDiary(DiaryModel diary) async {
    await _database.insertDiary(diary);
  }

  @override
  Future<void> updateDiary(DiaryModel diary) async {
    await _database.updateDiary(diary);
  }

  @override
  Future<void> deleteDiary(DateTime date, String userId) async {
    await _database.deleteDiaryByDateAndUserId(date, userId);
  }

  @override
  Future<DiaryModel?> getDiaryByDate(DateTime date, String userId) async {
    final result = await _database.getDiaryByDateAndUserId(date, userId);
    return result != null ? DiaryModel.fromMap(result.toMap()) : null;
  }

  @override
  Future<List<DiaryModel>> getDiariesByDateRange(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    final results = await _database.getDiariesByDateRangeAndUserId(
      startDate,
      endDate,
      userId,
    );
    return results.map((diary) => DiaryModel.fromMap(diary.toMap())).toList();
  }

  @override
  Future<bool> hasDiary(DateTime date, String userId) async {
    return await _database.hasDiaryOnDateAndUserId(date, userId);
  }

  @override
  Future<List<DiaryModel>> getAllDiaries(String userId) async {
    final results = await _database.getAllDiariesByUserId(userId);
    return results.map((diary) => DiaryModel.fromMap(diary.toMap())).toList();
  }
}