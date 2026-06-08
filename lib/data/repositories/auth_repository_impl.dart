import 'package:app_wallet/domain/entities/user_entity.dart';
import 'package:app_wallet/domain/repositories/auth_repository.dart';
import 'package:app_wallet/data/datasources/auth_remote_data_source.dart';
import 'package:app_wallet/core/error/failures.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> checkAuthStatus() async {
    // In original code this relied on SharedPreferences stored inside AuthProvider. 
    // For simplicity, we just return null here and let the ViewModel handle the shared_prefs logic, 
    // or we could abstract shared_prefs into a LocalDataSource.
    return null; 
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      return await remoteDataSource.login(email, password);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserEntity?> register(String name, String email, String password, {String phone = '', String avatar = ''}) async {
    try {
      return await remoteDataSource.register(name, email, password, phone: phone, avatar: avatar);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    // Handled by ViewModel / SharedPreferences
  }

  @override
  Future<UserEntity?> fetchUserModel(int userId) async {
    try {
      return await remoteDataSource.fetchUserModel(userId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserEntity?> updateUser(int userId, Map<String, dynamic> updates) async {
    try {
      return await remoteDataSource.updateUser(userId, updates);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
