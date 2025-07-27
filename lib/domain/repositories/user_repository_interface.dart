import '../entities/user_entity.dart';

abstract class IUserRepository {
  Future<UserEntity?> getCurrentUser();
  Future<void> saveUser(UserEntity user);
  Future<String?> getUserId();
  Future<DateTime?> getUserCreatedAt();
  Future<void> saveUserId(String userId);
  Future<void> saveUserCreatedAt(DateTime createdAt);
}