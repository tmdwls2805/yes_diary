import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/services/database_service.dart';

class DiaryNotifier extends StateNotifier<Map<DateTime, DiaryEntry>> {
  DiaryNotifier() : super({});

  Future<void> loadDiariesForRange(DateTime startDate, DateTime endDate, String userId) async {
    try {
      final diaries = await DatabaseService.instance.diaryRepository
          .getDiariesByDateRangeAndUserId(startDate, endDate, userId);
      
      final Map<DateTime, DiaryEntry> diaryMap = {};
      for (var entry in diaries) {
        final normalizedDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        diaryMap[normalizedDate] = entry;
      }
      
      state = {...state, ...diaryMap};
    } catch (e) {
      print('Failed to load diaries: $e');
    }
  }

  Future<void> saveDiary(DiaryEntry entry) async {
    try {
      await DatabaseService.instance.diaryRepository.insertDiary(entry);
      final normalizedDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      state = {...state, normalizedDate: entry};
    } catch (e) {
      print('Failed to save diary: $e');
    }
  }

  Future<void> updateDiary(DiaryEntry entry) async {
    try {
      await DatabaseService.instance.diaryRepository.updateDiary(entry);
      final normalizedDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      state = {...state, normalizedDate: entry};
    } catch (e) {
      print('Failed to update diary: $e');
    }
  }

  Future<void> deleteDiary(DateTime date, String userId) async {
    try {
      await DatabaseService.instance.diaryRepository.deleteDiaryByDateAndUserId(date, userId);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final newState = Map<DateTime, DiaryEntry>.from(state);
      newState.remove(normalizedDate);
      state = newState;
    } catch (e) {
      print('Failed to delete diary: $e');
    }
  }

  Future<bool> hasDiaryOnDate(DateTime date, String userId) async {
    try {
      return await DatabaseService.instance.diaryRepository.hasDiaryOnDateAndUserId(date, userId);
    } catch (e) {
      print('Failed to check diary existence: $e');
      return false;
    }
  }

  DiaryEntry? getDiaryForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return state[normalizedDate];
  }

  String? getEmotionForDate(DateTime date) {
    final diary = getDiaryForDate(date);
    return diary?.emotion;
  }
}

final diaryProvider = StateNotifierProvider<DiaryNotifier, Map<DateTime, DiaryEntry>>((ref) {
  return DiaryNotifier();
});

// Helper provider to get emotion for a specific date
final emotionForDateProvider = Provider.family<String?, DateTime>((ref, date) {
  final diaries = ref.watch(diaryProvider);
  final normalizedDate = DateTime(date.year, date.month, date.day);
  return diaries[normalizedDate]?.emotion;
});