class DiaryEntry {
  final DateTime date;
  final String content;
  final String emotion;
  final String? userId;

  DiaryEntry({
    required this.date,
    required this.content,
    required this.emotion,
    this.userId, // userId 필드 추가
  });

  /// DiaryEntry 객체를 Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'content': content,
      'emotion': emotion,
      'userId': userId, // userId 필드 추가
    };
  }

  /// Map에서 DiaryEntry 객체로 변환 (데이터베이스 조회용)
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      date: DateTime.parse(map['date']),
      content: map['content'],
      emotion: map['emotion'],
      userId: map['userId'], // userId 필드 추가
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntry &&
        other.date == date &&
        other.content == content &&
        other.emotion == emotion &&
        other.userId == userId; // userId 비교 추가
  }

  @override
  int get hashCode => date.hashCode ^ content.hashCode ^ emotion.hashCode ^ userId.hashCode;

  @override
  String toString() {
    return 'DiaryEntry(date: $date, content: $content, emotion: $emotion, userId: $userId)';
  }
} 