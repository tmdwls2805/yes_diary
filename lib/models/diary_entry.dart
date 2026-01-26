class DiaryEntry {
  final DateTime date;
  final String content;
  final int emotionId;
  final String? userId;

  DiaryEntry({
    required this.date,
    required this.content,
    required this.emotionId,
    this.userId,
  });

  /// 감정 이름을 ID로 변환하는 헬퍼 메서드
  static int emotionNameToId(String emotionName) {
    const emotionMap = {
      'red': 1,
      'yellow': 2,
      'blue': 3,
      'pink': 4,
      'green': 5,
    };
    return emotionMap[emotionName] ?? 1; // 기본값은 1 (red)
  }

  /// 감정 ID를 이름으로 변환하는 헬퍼 메서드
  static String emotionIdToName(int emotionId) {
    const idToNameMap = {
      1: 'red',
      2: 'yellow',
      3: 'blue',
      4: 'pink',
      5: 'green',
    };
    return idToNameMap[emotionId] ?? 'red'; // 기본값은 'red'
  }

  /// UI에서 사용할 감정 이름을 반환
  String get emotionName => emotionIdToName(emotionId);

  /// DiaryEntry 객체를 Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'content': content,
      'emotion_id': emotionId,
      'userId': userId,
    };
  }

  /// Map에서 DiaryEntry 객체로 변환 (데이터베이스 조회용)
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      date: DateTime.parse(map['date']),
      content: map['content'],
      emotionId: map['emotion_id'],
      userId: map['userId'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntry &&
        other.date == date &&
        other.content == content &&
        other.emotionId == emotionId &&
        other.userId == userId;
  }

  @override
  int get hashCode => date.hashCode ^ content.hashCode ^ emotionId.hashCode ^ userId.hashCode;

  @override
  String toString() {
    return 'DiaryEntry(date: $date, content: $content, emotionId: $emotionId, userId: $userId)';
  }
} 