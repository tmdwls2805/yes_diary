class UserEntity {
  final String userId;
  final DateTime createdAt;

  const UserEntity({
    required this.userId,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
        other.userId == userId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => userId.hashCode ^ createdAt.hashCode;

  @override
  String toString() {
    return 'UserEntity(userId: $userId, createdAt: $createdAt)';
  }
}