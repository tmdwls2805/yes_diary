import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository_interface.dart';
import '../datasources/local/user_local_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements IUserRepository {
  final UserLocalDataSource _localDataSource;

  UserRepositoryImpl(this._localDataSource);

  @override
  Future<UserEntity?> getCurrentUser() async {
    final model = await _localDataSource.getCurrentUser();
    return model?.toEntity();
  }

  @override
  Future<void> saveUser(UserEntity user) async {
    final model = UserModel.fromEntity(user);
    await _localDataSource.saveUser(model);
  }

  @override
  Future<String?> getUserId() async {
    return await _localDataSource.getUserId();
  }

  @override
  Future<DateTime?> getUserCreatedAt() async {
    return await _localDataSource.getUserCreatedAt();
  }

  @override
  Future<void> saveUserId(String userId) async {
    await _localDataSource.saveUserId(userId);
  }

  @override
  Future<void> saveUserCreatedAt(DateTime createdAt) async {
    await _localDataSource.saveUserCreatedAt(createdAt);
  }
}