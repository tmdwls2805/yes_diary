import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String userId,
    required DateTime createdAt,
  }) : super(
          userId: userId,
          createdAt: createdAt,
        );

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      userId: entity.userId,
      createdAt: entity.createdAt,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      userId: userId,
      createdAt: createdAt,
    );
  }
}