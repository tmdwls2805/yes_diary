import 'package:uuid/uuid.dart';
import '../../entities/user_entity.dart';
import '../../repositories/user_repository_interface.dart';

class InitializeUserUseCase {
  final IUserRepository _repository;

  InitializeUserUseCase(this._repository);

  Future<UserEntity> execute() async {
    final existingUser = await _repository.getCurrentUser();
    
    if (existingUser != null) {
      return existingUser;
    }

    // Create new user
    const uuid = Uuid();
    final now = DateTime.now();
    
    final newUser = UserEntity(
      userId: uuid.v4(),
      createdAt: now,
    );

    await _repository.saveUser(newUser);
    return newUser;
  }
}