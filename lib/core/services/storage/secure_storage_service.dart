import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:yes_diary/core/constants/storage_keys.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService() : _storage = const FlutterSecureStorage();

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: StorageKeys.userId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: StorageKeys.userId);
  }

  Future<void> saveCreatedAt(String createdAt) async {
    await _storage.write(key: StorageKeys.createdAt, value: createdAt);
  }

  Future<String?> getCreatedAt() async {
    return await _storage.read(key: StorageKeys.createdAt);
  }

  Future<void> saveLocalUserId(String localUserId) async {
    await _storage.write(key: StorageKeys.localUserId, value: localUserId);
  }

  Future<String?> getLocalUserId() async {
    return await _storage.read(key: StorageKeys.localUserId);
  }
} 