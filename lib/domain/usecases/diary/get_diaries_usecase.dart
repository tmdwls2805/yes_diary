import '../../entities/diary_entity.dart';
import '../../repositories/diary_repository_interface.dart';

class GetDiariesUseCase {
  final IDiaryRepository _repository;

  GetDiariesUseCase(this._repository);

  Future<List<DiaryEntity>> execute(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    if (startDate.isAfter(endDate)) {
      throw ArgumentError('Start date cannot be after end date');
    }

    return await _repository.getDiariesByDateRange(startDate, endDate, userId);
  }
}