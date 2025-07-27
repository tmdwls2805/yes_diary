import '../../repositories/diary_repository_interface.dart';

class DeleteDiaryUseCase {
  final IDiaryRepository _repository;

  DeleteDiaryUseCase(this._repository);

  Future<void> execute(DateTime date, String userId) async {
    await _repository.deleteDiary(date, userId);
  }
}