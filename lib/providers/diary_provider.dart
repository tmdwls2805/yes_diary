import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/services/auth_service.dart';

class DiaryNotifier extends StateNotifier<Map<DateTime, DiaryEntry>> {
  DiaryNotifier() : super({});

  final AuthService _authService = AuthService();

  /// 지정된 날짜 범위의 일기를 불러와 상태를 갱신합니다.
  /// 삭제된 항목을 반영하기 위해 해당 범위의 기존 상태를 지우고 새로 채웁니다.
  Future<void> loadDiariesForRange(DateTime startDate, DateTime endDate, String userId) async {
    try {
      final diaries = await DatabaseService.instance.diaryRepository
          .getDiariesByDateRangeAndUserId(startDate, endDate, userId);
      
      final Map<DateTime, DiaryEntry> diaryMap = {};
      for (var entry in diaries) {
        final normalizedDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        diaryMap[normalizedDate] = entry;
      }
      
      final newState = Map<DateTime, DiaryEntry>.from(state);
      
      // 로드하려는 범위 내의 기존 항목들을 먼저 상태에서 제거합니다.
      // 이렇게 해야 DB에서 삭제된 항목이 상태에도 반영됩니다.
      newState.removeWhere((date, entry) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        // 범위 비교를 위해 isAfter와 isBefore를 사용합니다.
        return !normalizedDate.isBefore(startDate) && 
               !normalizedDate.isAfter(endDate);
      });
      
      // 새로 불러온 항목들을 상태에 추가합니다.
      newState.addAll(diaryMap);
      
      state = newState;

    } catch (e) {
      print('Failed to load diaries: $e');
    }
  }

  /// 일기를 저장하거나 덮어씁니다.
  Future<void> saveDiary(DiaryEntry entry) async {
    try {
      await DatabaseService.instance.diaryRepository.insertDiary(entry);
      final normalizedDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      // 기존 상태에 새 항목을 추가하거나 갱신합니다.
      state = {...state, normalizedDate: entry};
    } catch (e) {
      print('Failed to save diary: $e');
    }
  }

  /// 일기를 수정합니다.
  Future<void> updateDiary(DiaryEntry entry) async {
    try {
      await DatabaseService.instance.diaryRepository.updateDiary(entry);
      final normalizedDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      // 기존 상태의 항목을 갱신합니다.
      state = {...state, normalizedDate: entry};
    } catch (e) {
      print('Failed to update diary: $e');
    }
  }

  /// 특정 날짜의 일기를 DB와 상태 모두에서 삭제합니다.
  Future<void> deleteDiary(DateTime date, String userId) async {
    try {
      await DatabaseService.instance.diaryRepository.deleteDiaryByDateAndUserId(date, userId);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      // 상태에서도 해당 항목을 제거합니다.
      final newState = Map<DateTime, DiaryEntry>.from(state);
      newState.remove(normalizedDate);
      state = newState;
    } catch (e) {
      print('Failed to delete diary: $e');
    }
  }

  /// 특정 날짜에 일기가 있는지 확인합니다. (상태 우선 확인)
  Future<bool> hasDiaryOnDate(DateTime date, String userId) async {
    try {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      // 먼저 상태(메모리)에서 빠르게 확인
      if (state.containsKey(normalizedDate)) {
        return true;
      }
      // 상태에 없으면 DB에서 확인
      return await DatabaseService.instance.diaryRepository.hasDiaryOnDateAndUserId(date, userId);
    } catch (e) {
      print('Failed to check diary existence: $e');
      return false;
    }
  }

  /// 특정 날짜의 일기 객체를 반환합니다.
  DiaryEntry? getDiaryForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return state[normalizedDate];
  }

  /// 특정 날짜의 감정 문자열을 반환합니다.
  String? getEmotionForDate(DateTime date) {
    final diary = getDiaryForDate(date);
    return diary?.emotionName;
  }

  /// 서버에서 월별 일기를 가져와서 로컬 DB에 저장하고 상태 업데이트
  Future<void> fetchAndSaveMonthlyDiaries(int year, int month, String userId) async {
    try {
      print('서버에서 $year년 $month월 일기 가져오는 중...');

      // 서버에서 월별 일기 조회
      final serverDiaries = await _authService.getMonthlyDiaries(year, month);

      if (serverDiaries.isEmpty) {
        print('서버에 $year년 $month월 일기가 없습니다');
        return;
      }

      print('서버에서 ${serverDiaries.length}개의 일기를 가져왔습니다');

      // 서버 데이터를 DiaryEntry로 변환하고 로컬 DB에 저장
      for (var diaryJson in serverDiaries) {
        try {
          final diaryEntry = DiaryEntry.fromServerJson(diaryJson);

          // 로컬 DB에 저장 (userId 포함)
          final entryWithUserId = diaryEntry.copyWith(userId: userId);
          await DatabaseService.instance.diaryRepository.insertDiary(entryWithUserId);

          // 상태 업데이트
          final normalizedDate = DateTime(
            entryWithUserId.date.year,
            entryWithUserId.date.month,
            entryWithUserId.date.day,
          );
          state = {...state, normalizedDate: entryWithUserId};

          print('일기 저장 완료: ${entryWithUserId.date} (serverId: ${entryWithUserId.serverId})');
        } catch (e) {
          print('일기 변환/저장 실패: $e');
          continue;
        }
      }

      print('$year년 $month월 일기 동기화 완료');
    } catch (e) {
      print('월별 일기 가져오기 실패: $e');
    }
  }
}

/// DiaryNotifier를 제공하는 메인 프로바이더
final diaryProvider = StateNotifierProvider<DiaryNotifier, Map<DateTime, DiaryEntry>>((ref) {
  return DiaryNotifier();
});

/// 특정 날짜(family)의 감정 정보를 제공하는 헬퍼 프로바이더
/// 캘린더 UI에서 각 날짜별로 감정을 watch하기 위해 사용됩니다.
final emotionForDateProvider = Provider.family<String?, DateTime>((ref, date) {
  final diaries = ref.watch(diaryProvider);
  final normalizedDate = DateTime(date.year, date.month, date.day);
  return diaries[normalizedDate]?.emotionName;
});