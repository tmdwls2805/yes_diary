class DiaryEntity {
  final DateTime date;
  final String content;
  final String emotion;
  final String userId;

  const DiaryEntity({
    required this.date,
    required this.content,
    required this.emotion,
    required this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntity &&
        other.date == date &&
        other.content == content &&
        other.emotion == emotion &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return date.hashCode ^
        content.hashCode ^
        emotion.hashCode ^
        userId.hashCode;
  }

  @override
  String toString() {
    return 'DiaryEntity(date: $date, content: $content, emotion: $emotion, userId: $userId)';
  }
}