import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';

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
}

final userProvider = StateNotifierProvider<UserNotifier, UserData>((ref) {
  return UserNotifier();
});