import 'package:app_wallet/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> checkAuthStatus();
  Future<UserEntity?> login(String email, String password);
  Future<UserEntity?> register(
    String name,
    String email,
    String password, {
    String phone = '',
    String avatar = '',
  });
  Future<void> logout();
  Future<UserEntity?> fetchUserModel(int userId);
  Future<UserEntity?> updateUser(int userId, Map<String, dynamic> updates);
}
