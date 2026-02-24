class DiaryEntry {
  final DateTime date;
  final String content;
  final int emotionId;
  final String? userId;
  final String? title;
  final int? serverId; // 서버와 동기화된 일기의 백엔드 ID
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DiaryEntry({
    required this.date,
    required this.content,
    required this.emotionId,
    this.userId,
    this.title,
    this.serverId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
      'title': title,
      'serverId': serverId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Map에서 DiaryEntry 객체로 변환 (데이터베이스 조회용)
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      date: DateTime.parse(map['date']),
      content: map['content'],
      emotionId: map['emotion_id'],
      userId: map['userId'],
      title: map['title'],
      serverId: map['serverId'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  /// 서버 동기화용 JSON 변환 (POST /api/diaries/sync)
  Map<String, dynamic> toSyncJson() {
    return {
      'localId': serverId, // 로컬에서는 serverId를 localId로 사용
      'title': title ?? '', // title이 없으면 빈 문자열
      'content': content,
      'emotionId': emotionId,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// 서버 응답에서 DiaryEntry 생성
  factory DiaryEntry.fromServerJson(Map<String, dynamic> json) {
    return DiaryEntry(
      date: DateTime.parse(json['date']),
      content: json['content'],
      emotionId: json['emotionInfo']?['id'] ?? json['emotionId'] ?? 1,
      userId: json['userId']?.toString(),
      title: json['title'],
      serverId: json['id'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntry &&
        other.date == date &&
        other.content == content &&
        other.emotionId == emotionId &&
        other.userId == userId &&
        other.title == title &&
        other.serverId == serverId;
  }

  @override
  int get hashCode =>
      date.hashCode ^
      content.hashCode ^
      emotionId.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      serverId.hashCode;

  @override
  String toString() {
    return 'DiaryEntry(date: $date, content: $content, emotionId: $emotionId, userId: $userId, title: $title, serverId: $serverId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  /// DiaryEntry 복사 (업데이트용)
  DiaryEntry copyWith({
    DateTime? date,
    String? content,
    int? emotionId,
    String? userId,
    String? title,
    int? serverId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      date: date ?? this.date,
      content: content ?? this.content,
      emotionId: emotionId ?? this.emotionId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // 업데이트 시 현재 시간으로
    );
  }
} 