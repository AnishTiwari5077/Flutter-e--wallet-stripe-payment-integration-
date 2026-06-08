import 'dart:convert';
import 'package:app_wallet/core/network/api_client.dart';
import 'package:app_wallet/data/models/user_model.dart';
import 'package:app_wallet/core/error/failures.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register(String name, String email, String password, {String phone = '', String avatar = ''});
  Future<UserModel> login(String email, String password);
  Future<UserModel> fetchUserModel(int userId);
  Future<UserModel> updateUser(int userId, Map<String, dynamic> updates);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient client;
  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<UserModel> register(String name, String email, String password, {String phone = '', String avatar = ''}) async {
    final response = await client.post('/register', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'avatar': avatar,
    });
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data.containsKey('user')) {
        return UserModel.fromJson(data['user']);
      }
      throw const ServerFailure('Invalid UserEntity data received');
    } else {
      final data = jsonDecode(response.body);
      throw ServerFailure(data['error'] ?? 'Server error');
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await client.post('/login', {'email': email, 'password': password});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data.containsKey('user')) {
        return UserModel.fromJson(data['user']);
      }
      throw const ServerFailure('Invalid UserEntity data received');
    } else {
      final data = jsonDecode(response.body);
      throw ServerFailure(data['error'] ?? 'Login failed');
    }
  }

  @override
  Future<UserModel> fetchUserModel(int userId) async {
    final response = await client.get('/user/$userId');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw ServerFailure('Failed to fetch UserEntity');
    }
  }

  @override
  Future<UserModel> updateUser(int userId, Map<String, dynamic> updates) async {
    final response = await client.put('/user/$userId', updates);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data.containsKey('user')) {
        return UserModel.fromJson(data['user']);
      }
      throw const ServerFailure('Invalid UserEntity data received');
    } else {
      throw ServerFailure('Failed to update UserEntity');
    }
  }
}
