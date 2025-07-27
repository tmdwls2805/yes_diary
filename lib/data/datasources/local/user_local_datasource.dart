import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../../core/services/storage/secure_storage_service.dart';

abstract class UserLocalDataSource {
  Future<UserModel?> getCurrentUser();
  Future<void> saveUser(UserModel user);
  Future<String?> getUserId();
  Future<DateTime?> getUserCreatedAt();
  Future<void> saveUserId(String userId);
  Future<void> saveUserCreatedAt(DateTime createdAt);
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final SecureStorageService _secureStorage;

  UserLocalDataSourceImpl(this._secureStorage);

  @override
  Future<UserModel?> getCurrentUser() async {
    final userId = await _secureStorage.getUserId();
    final createdAtString = await _secureStorage.getCreatedAt();

    if (userId != null && createdAtString != null) {
      return UserModel(
        userId: userId,
        createdAt: DateTime.parse(createdAtString),
      );
    }

    return null;
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await _secureStorage.saveUserId(user.userId);
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    await _secureStorage.saveCreatedAt(formatter.format(user.createdAt));
  }

  @override
  Future<String?> getUserId() async {
    return await _secureStorage.getUserId();
  }

  @override
  Future<DateTime?> getUserCreatedAt() async {
    final createdAtString = await _secureStorage.getCreatedAt();
    return createdAtString != null ? DateTime.parse(createdAtString) : null;
  }

  @override
  Future<void> saveUserId(String userId) async {
    await _secureStorage.saveUserId(userId);
  }

  @override
  Future<void> saveUserCreatedAt(DateTime createdAt) async {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    await _secureStorage.saveCreatedAt(formatter.format(createdAt));
  }
}