import '../../domain/entities/diary_entity.dart';
import '../../domain/repositories/diary_repository_interface.dart';
import '../datasources/local/diary_local_datasource.dart';
import '../models/diary_model.dart';

class DiaryRepositoryImpl implements IDiaryRepository {
  final DiaryLocalDataSource _localDataSource;

  DiaryRepositoryImpl(this._localDataSource);

  @override
  Future<void> createDiary(DiaryEntity diary) async {
    final model = DiaryModel.fromEntity(diary);
    await _localDataSource.insertDiary(model);
  }

  @override
  Future<void> updateDiary(DiaryEntity diary) async {
    final model = DiaryModel.fromEntity(diary);
    await _localDataSource.updateDiary(model);
  }

  @override
  Future<void> deleteDiary(DateTime date, String userId) async {
    await _localDataSource.deleteDiary(date, userId);
  }

  @override
  Future<DiaryEntity?> getDiaryByDate(DateTime date, String userId) async {
    final model = await _localDataSource.getDiaryByDate(date, userId);
    return model?.toEntity();
  }

  @override
  Future<List<DiaryEntity>> getDiariesByDateRange(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    final models = await _localDataSource.getDiariesByDateRange(
      startDate,
      endDate,
      userId,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<bool> hasDiary(DateTime date, String userId) async {
    return await _localDataSource.hasDiary(date, userId);
  }

  @override
  Future<List<DiaryEntity>> getAllDiaries(String userId) async {
    final models = await _localDataSource.getAllDiaries(userId);
    return models.map((model) => model.toEntity()).toList();
  }
}