import 'package:flutter_test/flutter_test.dart';
import 'package:yes_diary/models/diary_entry.dart';

void main() {
  group('DiaryEntry 모델 테스트', () {
    test('DiaryEntry 생성 시 모든 필드가 올바르게 설정되는지 확인', () {
      // Given
      final date = DateTime(2024, 1, 1);
      const content = '오늘은 좋은 하루였다.';
      const emotionId = 5; // green

      // When
      final entry = DiaryEntry(
        date: date,
        content: content,
        emotionId: emotionId,
      );

      // Then
      expect(entry.date, equals(date));
      expect(entry.content, equals(content));
      expect(entry.emotionId, equals(emotionId));
      expect(entry.emotionName, equals('green'));
    });

    test('DiaryEntry를 Map으로 변환하는 테스트', () {
      // Given
      final date = DateTime(2024, 1, 1);
      const content = '오늘은 좋은 하루였다.';
      const emotionId = 5; // green
      final entry = DiaryEntry(
        date: date,
        content: content,
        emotionId: emotionId,
      );

      // When
      final map = entry.toMap();

      // Then
      expect(map['date'], equals(date.toIso8601String()));
      expect(map['content'], equals(content));
      expect(map['emotion_id'], equals(emotionId));
    });

    test('Map에서 DiaryEntry 객체로 변환하는 테스트', () {
      // Given
      final date = DateTime(2024, 1, 1);
      const content = '오늘은 좋은 하루였다.';
      const emotionId = 5; // green
      final map = {
        'date': date.toIso8601String(),
        'content': content,
        'emotion_id': emotionId,
      };

      // When
      final entry = DiaryEntry.fromMap(map);

      // Then
      expect(entry.date, equals(date));
      expect(entry.content, equals(content));
      expect(entry.emotionId, equals(emotionId));
      expect(entry.emotionName, equals('green'));
    });

    test('유효한 감정 이미지 타입 검증', () {
      // Given
      final validEmotionIds = [1, 2, 3, 4, 5]; // red, yellow, blue, pink, green
      final date = DateTime(2024, 1, 1);
      const content = '테스트 내용';

      // When & Then
      for (final emotionId in validEmotionIds) {
        expect(
          () => DiaryEntry(
            date: date,
            content: content,
            emotionId: emotionId,
          ),
          returnsNormally,
        );
      }
    });

    test('날짜 고유성 검증을 위한 equality 테스트', () {
      // Given
      final date = DateTime(2024, 1, 1);
      const content1 = '첫 번째 일기';
      const content2 = '두 번째 일기';
      const emotionId = 5; // green

      final entry1 = DiaryEntry(
        date: date,
        content: content1,
        emotionId: emotionId,
      );

      final entry2 = DiaryEntry(
        date: date,
        content: content2,
        emotionId: emotionId,
      );

      // When & Then
      expect(entry1.date, equals(entry2.date));
      expect(entry1 != entry2, true); // 내용이 다르면 다른 객체
    });
  });
} 