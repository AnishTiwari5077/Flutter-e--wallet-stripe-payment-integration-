import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_wallet/core/error/failures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_wallet/domain/entities/user_entity.dart';
import 'package:app_wallet/data/models/user_model.dart';
import 'package:app_wallet/domain/usecases/auth_usecases.dart';
import 'package:app_wallet/services/biometric_service.dart';

class AuthProvider with ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final FetchUserUseCase fetchUserUseCase;

  AuthProvider({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.fetchUserUseCase,
  });

  UserEntity? _user;
  bool _loading = false;
  String? _errorMessage;

  UserEntity? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loggedInUser = await loginUseCase.call(email, password);
      if (loggedInUser != null) {
        _user = loggedInUser;
        await _saveUserToLocal(_user!);

        final biometricEnabled = await BiometricService.isBiometricEnabledForLogin();
        if (biometricEnabled) {
          await BiometricService.storeBiometricCredentials(email, password);
        }

        _loading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (e is Failure) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    String phone = '',
    String avatar = '',
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final registeredUser = await registerUseCase.call(name, email, password, phone: phone, avatar: avatar);
      if (registeredUser != null) {
        _user = registeredUser;
        await _saveUserToLocal(_user!);

        final biometricEnabled = await BiometricService.isBiometricEnabledForLogin();
        if (biometricEnabled) {
          await BiometricService.storeBiometricCredentials(email, password);
        }

        _loading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (e is Failure) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _errorMessage = null;
    _loading = false;
    notifyListeners();
    await _clearUserFromLocal();
  }

  Future<bool> checkAuthStatus() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        // Simplified restoration for viewmodel level
        _user = UserModel.fromJson(userMap);

        if (_user?.id != null) {
          try {
            final freshUser = await fetchUserUseCase.call(_user!.id!);
            if (freshUser != null) {
              _user = freshUser;
              await _saveUserToLocal(_user!);
            }
          } catch (_) {}
        }

        _loading = false;
        notifyListeners();
        return true;
      }

      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    if (_user?.id == null) return;
    try {
      final freshUser = await fetchUserUseCase.call(_user!.id!);
      if (freshUser != null) {
        _user = freshUser;
        await _saveUserToLocal(_user!);
        notifyListeners();
      }
    } catch (_) {}
  }

  void updateBalance(double newBalance) {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        phone: _user!.phone,
        avatar: _user!.avatar,
        balance: newBalance,
      );
      _saveUserToLocal(_user!);
      notifyListeners();
    }
  }

  void updateUser(UserEntity updatedUser) {
    if (_user != updatedUser) {
      _user = updatedUser;
      _saveUserToLocal(_user!);
      notifyListeners();
    }
  }

  void addMoney(double amount) {
    if (_user != null) {
      updateBalance(_user!.balance + amount);
    }
  }

  void deductMoney(double amount) {
    if (_user != null && _user!.balance >= amount) {
      updateBalance(_user!.balance - amount);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _saveUserToLocal(UserEntity userToSave) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userMap = {
        'id': userToSave.id,
        'name': userToSave.name,
        'email': userToSave.email,
        'phone': userToSave.phone,
        'avatar': userToSave.avatar,
        'balance': userToSave.balance,
      };
      await prefs.setString('user', jsonEncode(userMap));
    } catch (_) {}
  }

  Future<void> _clearUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    } catch (_) {}
  }
}
