import '../../entities/user_entity.dart';
import '../../repositories/user_repository_interface.dart';

class GetUserUseCase {
  final IUserRepository _repository;

  GetUserUseCase(this._repository);

  Future<UserEntity?> execute() async {
    return await _repository.getCurrentUser();
  }
}