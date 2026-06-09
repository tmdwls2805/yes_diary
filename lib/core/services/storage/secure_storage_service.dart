import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yes_diary/core/constants/storage_keys.dart';
import 'package:yes_diary/core/services/widget/widget_sync_service.dart';

class SecureStorageService {
  static const String _databaseName = 'diary_v4.db';
  static const String _installMarkerName = '.yes_diary_install_marker';

  final FlutterSecureStorage _storage;

  SecureStorageService() : _storage = const FlutterSecureStorage();

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: StorageKeys.userId, value: userId);
  }

  /// iOS Keychain은 앱 삭제 후에도 남을 수 있습니다.
  /// 앱 컨테이너의 DB/마커가 모두 없으면 재설치로 보고 SecureStorage를 초기화합니다.
  Future<void> resetIfFreshInstall() async {
    final databasePath = await getDatabasesPath();
    final markerFile = File('$databasePath/$_installMarkerName');
    final databaseFile = File('$databasePath/$_databaseName');

    final hasInstallMarker = await markerFile.exists();
    final hasLocalDatabase = await databaseFile.exists();

    if (!hasInstallMarker && !hasLocalDatabase) {
      await _storage.deleteAll();
    }

    if (!hasInstallMarker) {
      await Directory(databasePath).create(recursive: true);
      await markerFile.writeAsString(DateTime.now().toIso8601String());
    }
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
    await _storage.write(key: StorageKeys.onboardingNickname, value: nickname);
    await _storage.write(
        key: StorageKeys.onboardingDepartment, value: department);
    await _storage.write(
        key: StorageKeys.onboardingStartTime, value: startTime);
    await _storage.write(key: StorageKeys.onboardingEndTime, value: endTime);
    await _storage.write(key: StorageKeys.onboardingEmotion, value: emotion);
    await _storage.write(key: StorageKeys.onboardingCompleted, value: 'true');
    await WidgetSyncService.syncWorkSchedule(
      startTime: startTime,
      endTime: endTime,
    );
  }

  Future<bool> isOnboardingCompleted() async {
    return await _storage.read(key: StorageKeys.onboardingCompleted) == 'true';
  }

  Future<void> clearOnboardingProfile() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.onboardingCompleted),
      _storage.delete(key: StorageKeys.onboardingNickname),
      _storage.delete(key: StorageKeys.onboardingDepartment),
      _storage.delete(key: StorageKeys.onboardingStartTime),
      _storage.delete(key: StorageKeys.onboardingEndTime),
      _storage.delete(key: StorageKeys.onboardingEmotion),
      _storage.delete(key: StorageKeys.homeBedTimeDate),
    ]);
  }

  Future<void> saveHomeBedTimeDate(String date) async {
    await _storage.write(key: StorageKeys.homeBedTimeDate, value: date);
  }

  Future<String?> getHomeBedTimeDate() async {
    return await _storage.read(key: StorageKeys.homeBedTimeDate);
  }

  Future<void> saveOnboardingNickname(String nickname) async {
    await _storage.write(key: StorageKeys.onboardingNickname, value: nickname);
  }

  Future<void> saveOnboardingDepartment(String department) async {
    await _storage.write(
        key: StorageKeys.onboardingDepartment, value: department);
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
