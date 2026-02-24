import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:uuid/uuid.dart';

class UserData {
  final String? userId;
  final DateTime? createdAt;

  UserData({this.userId, this.createdAt});

  UserData copyWith({
    String? userId,
    DateTime? createdAt,
  }) {
    return UserData(
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UserNotifier extends StateNotifier<UserData> {
  UserNotifier() : super(UserData()) {
    _loadUserData();
  }

  final _secureStorageService = SecureStorageService();

  Future<void> _loadUserData() async {
    try {
      final userIdString = await _secureStorageService.getUserId();
      final createdAtString = await _secureStorageService.getCreatedAt();
      
      DateTime? createdAt;
      if (createdAtString != null) {
        createdAt = DateTime.parse(createdAtString);
      }

      state = UserData(
        userId: userIdString,
        createdAt: createdAt,
      );
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

  Future<void> saveUserId(String userId) async {
    await _secureStorageService.saveUserId(userId);
    state = state.copyWith(userId: userId);
  }

  Future<void> saveCreatedAt(DateTime createdAt) async {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    await _secureStorageService.saveCreatedAt(formatter.format(createdAt));
    state = state.copyWith(createdAt: createdAt);
  }

  /// 로그아웃: 원래의 로컬 UUID로 복귀
  Future<String> logout() async {
    // 저장된 로컬 UUID 가져오기
    final localUserId = await _secureStorageService.getLocalUserId();

    if (localUserId == null) {
      // 로컬 UUID가 없으면 새로 생성 (비상 상황)
      const uuid = Uuid();
      final newLocalUserId = uuid.v4();
      await _secureStorageService.saveLocalUserId(newLocalUserId);
      await saveUserId(newLocalUserId);
      print('로그아웃 완료: 로컬 UUID가 없어 새로 생성 - $newLocalUserId');
      return newLocalUserId;
    }

    // 원래의 로컬 UUID로 복귀
    await saveUserId(localUserId);
    print('로그아웃 완료: 원래의 로컬 UUID로 복귀 - $localUserId');
    return localUserId;
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserData>((ref) {
  return UserNotifier();
});