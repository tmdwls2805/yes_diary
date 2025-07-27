import '../../entities/diary_entity.dart';
import '../../repositories/diary_repository_interface.dart';

class UpdateDiaryUseCase {
  final IDiaryRepository _repository;

  UpdateDiaryUseCase(this._repository);

  Future<void> execute(DiaryEntity diary) async {
    if (diary.content.isEmpty) {
      throw ArgumentError('Diary content cannot be empty');
    }
    
    if (diary.content.length > 2000) {
      throw ArgumentError('Diary content cannot exceed 2000 characters');
    }

    await _repository.updateDiary(diary);
  }
}