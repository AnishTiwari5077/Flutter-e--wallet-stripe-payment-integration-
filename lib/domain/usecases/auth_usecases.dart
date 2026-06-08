import 'package:app_wallet/domain/entities/user_entity.dart';
import 'package:app_wallet/domain/repositories/auth_repository.dart';

class CheckAuthUseCase {
  final AuthRepository repository;
  CheckAuthUseCase(this.repository);
  Future<UserEntity?> call() => repository.checkAuthStatus();
}

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);
  Future<UserEntity?> call(String email, String password) =>
      repository.login(email, password);
}

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);
  Future<UserEntity?> call(
    String name,
    String email,
    String password, {
    String phone = '',
    String avatar = '',
  }) => repository.register(name, email, password, phone: phone, avatar: avatar);
}

class LogoutUseCase {
  final AuthRepository repository;
  LogoutUseCase(this.repository);
  Future<void> call() => repository.logout();
}

class FetchUserUseCase {
  final AuthRepository repository;
  FetchUserUseCase(this.repository);
  Future<UserEntity?> call(int userId) => repository.fetchUserModel(userId);
}

class UpdateUserUseCase {
  final AuthRepository repository;
  UpdateUserUseCase(this.repository);
  Future<UserEntity?> call(int userId, Map<String, dynamic> updates) =>
      repository.updateUser(userId, updates);
}
