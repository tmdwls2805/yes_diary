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
  String? localUserId = await secureStorageService.getLocalUserId();
  String? createdAt = await secureStorageService.getCreatedAt();

  // 최초 로컬 UUID가 없으면 생성 (한 번만 생성, 영구 보관)
  if (localUserId == null) {
    localUserId = uuid.v4();
    await secureStorageService.saveLocalUserId(localUserId);
    print('새 로컬 UUID 생성 및 저장: $localUserId');
  } else {
    print('기존 로컬 UUID 로드: $localUserId');
  }

  // 현재 userId가 없으면 로컬 UUID 사용
  if (userId == null) {
    userId = localUserId;
    await userNotifier.saveUserId(userId);
    print('로컬 UUID를 현재 userId로 설정: $userId');
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