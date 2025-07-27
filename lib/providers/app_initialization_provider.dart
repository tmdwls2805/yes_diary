import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:yes_diary/providers/user_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

final appInitializationProvider = FutureProvider<void>((ref) async {
  final secureStorageService = SecureStorageService();
  final userNotifier = ref.read(userProvider.notifier);
  const uuid = Uuid();
  final now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  String? userId = await secureStorageService.getUserId();
  String? createdAt = await secureStorageService.getCreatedAt();

  if (userId == null) {
    userId = uuid.v4();
    await userNotifier.saveUserId(userId);
    print('새 사용자 ID 생성 및 저장: $userId');
  } else {
    print('기존 사용자 ID 로드: $userId');
  }

  if (createdAt == null) {
    await userNotifier.saveCreatedAt(now);
    print('새 createdAt 생성 및 저장: ${formatter.format(now)}');
  } else {
    print('기존 createdAt 로드: $createdAt');
  }
});