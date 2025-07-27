import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/user/get_user_usecase.dart';
import '../../domain/usecases/user/initialize_user_usecase.dart';

class UserState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserViewModel extends StateNotifier<UserState> {
  final GetUserUseCase _getUserUseCase;
  final InitializeUserUseCase _initializeUserUseCase;

  UserViewModel({
    required GetUserUseCase getUserUseCase,
    required InitializeUserUseCase initializeUserUseCase,
  })  : _getUserUseCase = getUserUseCase,
        _initializeUserUseCase = initializeUserUseCase,
        super(UserState()) {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final user = await _initializeUserUseCase.execute();
      
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUser() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final user = await _getUserUseCase.execute();
      
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}