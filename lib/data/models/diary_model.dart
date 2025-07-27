import '../../domain/entities/diary_entity.dart';

class DiaryModel extends DiaryEntity {
  const DiaryModel({
    required DateTime date,
    required String content,
    required String emotion,
    required String userId,
  }) : super(
          date: date,
          content: content,
          emotion: emotion,
          userId: userId,
        );

  factory DiaryModel.fromEntity(DiaryEntity entity) {
    return DiaryModel(
      date: entity.date,
      content: entity.content,
      emotion: entity.emotion,
      userId: entity.userId,
    );
  }

  factory DiaryModel.fromMap(Map<String, dynamic> map) {
    return DiaryModel(
      date: DateTime.parse(map['date']),
      content: map['content'],
      emotion: map['emotion'],
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'content': content,
      'emotion': emotion,
      'userId': userId,
    };
  }

  DiaryEntity toEntity() {
    return DiaryEntity(
      date: date,
      content: content,
      emotion: emotion,
      userId: userId,
    );
  }
}