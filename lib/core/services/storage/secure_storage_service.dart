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

  Future<void> saveOnboardingProfile({
    required String nickname,
    required String department,
    required String startTime,
    required String endTime,
    required String emotion,
  }) async {
    await _storage.write(
        key: StorageKeys.onboardingNickname, value: nickname);
    await _storage.write(
        key: StorageKeys.onboardingDepartment, value: department);
    await _storage.write(
        key: StorageKeys.onboardingStartTime, value: startTime);
    await _storage.write(
        key: StorageKeys.onboardingEndTime, value: endTime);
    await _storage.write(
        key: StorageKeys.onboardingEmotion, value: emotion);
  }

  Future<Map<String, String?>> getOnboardingProfile() async {
    return {
      'nickname': await _storage.read(key: StorageKeys.onboardingNickname),
      'department': await _storage.read(key: StorageKeys.onboardingDepartment),
      'startTime': await _storage.read(key: StorageKeys.onboardingStartTime),
      'endTime': await _storage.read(key: StorageKeys.onboardingEndTime),
      'emotion': await _storage.read(key: StorageKeys.onboardingEmotion),
    };
  }
} 