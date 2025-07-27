import 'package:flutter_riverpod/flutter_riverpod.dart';

// Database
import '../../database/diary_database.dart';
import '../../services/database_service.dart';

// Core Services
import '../services/storage/secure_storage_service.dart';

// Data Sources
import '../../data/datasources/local/diary_local_datasource.dart';
import '../../data/datasources/local/user_local_datasource.dart';

// Repositories
import '../../domain/repositories/diary_repository_interface.dart';
import '../../domain/repositories/user_repository_interface.dart';
import '../../data/repositories/diary_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';

// Use Cases
import '../../domain/usecases/diary/create_diary_usecase.dart';
import '../../domain/usecases/diary/update_diary_usecase.dart';
import '../../domain/usecases/diary/delete_diary_usecase.dart';
import '../../domain/usecases/diary/get_diaries_usecase.dart';
import '../../domain/usecases/user/get_user_usecase.dart';
import '../../domain/usecases/user/initialize_user_usecase.dart';

// ViewModels
import '../../presentation/viewmodels/diary_viewmodel.dart';
import '../../presentation/viewmodels/user_viewmodel.dart';
import '../../presentation/viewmodels/calendar_viewmodel.dart';

// External Dependencies
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final diaryDatabaseProvider = Provider<DiaryDatabase>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.diaryDatabase;
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Data Sources
final diaryLocalDataSourceProvider = Provider<DiaryLocalDataSource>((ref) {
  final database = ref.watch(diaryDatabaseProvider);
  return DiaryLocalDataSourceImpl(database);
});

final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return UserLocalDataSourceImpl(secureStorage);
});

// Repositories
final diaryRepositoryProvider = Provider<IDiaryRepository>((ref) {
  final localDataSource = ref.watch(diaryLocalDataSourceProvider);
  return DiaryRepositoryImpl(localDataSource);
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  final localDataSource = ref.watch(userLocalDataSourceProvider);
  return UserRepositoryImpl(localDataSource);
});

// Use Cases
final createDiaryUseCaseProvider = Provider<CreateDiaryUseCase>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return CreateDiaryUseCase(repository);
});

final updateDiaryUseCaseProvider = Provider<UpdateDiaryUseCase>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return UpdateDiaryUseCase(repository);
});

final deleteDiaryUseCaseProvider = Provider<DeleteDiaryUseCase>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return DeleteDiaryUseCase(repository);
});

final getDiariesUseCaseProvider = Provider<GetDiariesUseCase>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return GetDiariesUseCase(repository);
});

final getUserUseCaseProvider = Provider<GetUserUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserUseCase(repository);
});

final initializeUserUseCaseProvider = Provider<InitializeUserUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return InitializeUserUseCase(repository);
});

// ViewModels
final diaryViewModelProvider = StateNotifierProvider<DiaryViewModel, DiaryState>((ref) {
  return DiaryViewModel(
    createDiaryUseCase: ref.watch(createDiaryUseCaseProvider),
    updateDiaryUseCase: ref.watch(updateDiaryUseCaseProvider),
    deleteDiaryUseCase: ref.watch(deleteDiaryUseCaseProvider),
    getDiariesUseCase: ref.watch(getDiariesUseCaseProvider),
  );
});

final userViewModelProvider = StateNotifierProvider<UserViewModel, UserState>((ref) {
  return UserViewModel(
    getUserUseCase: ref.watch(getUserUseCaseProvider),
    initializeUserUseCase: ref.watch(initializeUserUseCaseProvider),
  );
});

final calendarViewModelProvider = StateNotifierProvider<CalendarViewModel, CalendarState>((ref) {
  return CalendarViewModel();
});

// Helper Providers
final emotionForDateProvider = Provider.family<String?, DateTime>((ref, date) {
  final diaryState = ref.watch(diaryViewModelProvider);
  final normalizedDate = DateTime(date.year, date.month, date.day);
  return diaryState.diaries[normalizedDate]?.emotion;
});