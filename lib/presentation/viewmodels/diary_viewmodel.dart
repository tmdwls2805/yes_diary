import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/diary_entity.dart';
import '../../domain/usecases/diary/create_diary_usecase.dart';
import '../../domain/usecases/diary/update_diary_usecase.dart';
import '../../domain/usecases/diary/delete_diary_usecase.dart';
import '../../domain/usecases/diary/get_diaries_usecase.dart';

class DiaryState {
  final Map<DateTime, DiaryEntity> diaries;
  final bool isLoading;
  final String? error;

  DiaryState({
    this.diaries = const {},
    this.isLoading = false,
    this.error,
  });

  DiaryState copyWith({
    Map<DateTime, DiaryEntity>? diaries,
    bool? isLoading,
    String? error,
  }) {
    return DiaryState(
      diaries: diaries ?? this.diaries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DiaryViewModel extends StateNotifier<DiaryState> {
  final CreateDiaryUseCase _createDiaryUseCase;
  final UpdateDiaryUseCase _updateDiaryUseCase;
  final DeleteDiaryUseCase _deleteDiaryUseCase;
  final GetDiariesUseCase _getDiariesUseCase;

  DiaryViewModel({
    required CreateDiaryUseCase createDiaryUseCase,
    required UpdateDiaryUseCase updateDiaryUseCase,
    required DeleteDiaryUseCase deleteDiaryUseCase,
    required GetDiariesUseCase getDiariesUseCase,
  })  : _createDiaryUseCase = createDiaryUseCase,
        _updateDiaryUseCase = updateDiaryUseCase,
        _deleteDiaryUseCase = deleteDiaryUseCase,
        _getDiariesUseCase = getDiariesUseCase,
        super(DiaryState());

  Future<void> loadDiariesForRange(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final diaries = await _getDiariesUseCase.execute(startDate, endDate, userId);
      
      final Map<DateTime, DiaryEntity> diaryMap = {};
      for (var diary in diaries) {
        final normalizedDate = DateTime(diary.date.year, diary.date.month, diary.date.day);
        diaryMap[normalizedDate] = diary;
      }
      
      state = state.copyWith(
        diaries: {...state.diaries, ...diaryMap},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadDiaryForDate(DateTime date, String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final diaries = await _getDiariesUseCase.execute(startDate, endDate, userId);
      
      final Map<DateTime, DiaryEntity> diaryMap = {};
      for (var diary in diaries) {
        final normalizedDate = DateTime(diary.date.year, diary.date.month, diary.date.day);
        diaryMap[normalizedDate] = diary;
      }
      
      state = state.copyWith(
        diaries: {...state.diaries, ...diaryMap},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createDiary(DiaryEntity diary) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _createDiaryUseCase.execute(diary);
      
      final normalizedDate = DateTime(diary.date.year, diary.date.month, diary.date.day);
      final updatedDiaries = Map<DateTime, DiaryEntity>.from(state.diaries);
      updatedDiaries[normalizedDate] = diary;
      
      state = state.copyWith(diaries: updatedDiaries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateDiary(DiaryEntity diary) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _updateDiaryUseCase.execute(diary);
      
      final normalizedDate = DateTime(diary.date.year, diary.date.month, diary.date.day);
      final updatedDiaries = Map<DateTime, DiaryEntity>.from(state.diaries);
      updatedDiaries[normalizedDate] = diary;
      
      state = state.copyWith(diaries: updatedDiaries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteDiary(DateTime date, String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _deleteDiaryUseCase.execute(date, userId);
      
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final updatedDiaries = Map<DateTime, DiaryEntity>.from(state.diaries);
      updatedDiaries.remove(normalizedDate);
      
      state = state.copyWith(diaries: updatedDiaries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  DiaryEntity? getDiaryForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return state.diaries[normalizedDate];
  }

  String? getEmotionForDate(DateTime date) {
    final diary = getDiaryForDate(date);
    return diary?.emotion;
  }
}