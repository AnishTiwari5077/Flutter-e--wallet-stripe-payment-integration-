import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_services.dart';
import '../services/biometric_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  // ============================================
  // LOGIN
  // ============================================
  Future<bool> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password);

      if (result['success'] == true && result['user'] != null) {
        _user = result['user'];
        await _saveUserToLocal(_user!);

        // Store credentials for biometric login if enabled
        final biometricEnabled =
            await BiometricService.isBiometricEnabledForLogin();
        if (biometricEnabled) {
          await BiometricService.storeBiometricCredentials(email, password);
        }

        _loading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Login failed';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // REGISTER
  // ============================================
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
      final result = await ApiService.register(
        name,
        email,
        password,
        phone: phone,
        avatar: avatar,
      );

      if (result['success'] == true && result['user'] != null) {
        _user = result['user'];
        await _saveUserToLocal(_user!);

        // Store credentials for biometric login if enabled
        final biometricEnabled =
            await BiometricService.isBiometricEnabledForLogin();
        if (biometricEnabled) {
          await BiometricService.storeBiometricCredentials(email, password);
        }

        _loading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Registration failed';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // LOGOUT
  // ============================================
  Future<void> logout() async {
    _user = null;
    _errorMessage = null;

    // Clear user data from local storage
    // await _clearUserFromLocal();

    // Clear biometric credentials
    // await BiometricService.clearBiometricCredentials();

    notifyListeners();
  }

  // ============================================
  // CHECK AUTH STATUS
  // ============================================
  Future<bool> checkAuthStatus() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        try {
          final userMap = jsonDecode(userJson);
          _user = User.fromJson(userMap);

          // Optionally refresh from server
          if (_user?.id != null) {
            final freshUser = await ApiService.fetchUser(_user!.id!);
            if (freshUser != null) {
              _user = freshUser;
              await _saveUserToLocal(_user!);
            }
          }

          _loading = false;
          notifyListeners();
          return true;
        } catch (e) {
          print('Error parsing local user data: $e');
          await _clearUserFromLocal();
          _user = null;
        }
      }

      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Check auth status error: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // REFRESH USER
  // ============================================
  Future<void> refreshUser() async {
    if (_user?.id == null) return;

    try {
      final freshUser = await ApiService.fetchUser(_user!.id!);

      if (freshUser != null) {
        _user = freshUser;
        await _saveUserToLocal(_user!);
        notifyListeners();
      }
    } catch (e) {
      print('Refresh user error: $e');
    }
  }

  // ============================================
  // UPDATE BALANCE
  // ============================================
  void updateBalance(double newBalance) {
    if (_user != null) {
      _user = _user!.copyWith(balance: newBalance);
      _saveUserToLocal(_user!);
      notifyListeners();
    }
  }

  // ============================================
  // UPDATE USER
  // ============================================
  void updateUser(User updatedUser) {
    if (_user != updatedUser) {
      _user = updatedUser;
      _saveUserToLocal(_user!);
      notifyListeners();
    }
  }

  // ============================================
  // ADD MONEY
  // ============================================
  void addMoney(double amount) {
    if (_user != null) {
      updateBalance(_user!.balance + amount);
    }
  }

  // ============================================
  // DEDUCT MONEY
  // ============================================
  void deductMoney(double amount) {
    if (_user != null && _user!.balance >= amount) {
      updateBalance(_user!.balance - amount);
    }
  }

  // ============================================
  // CLEAR ERROR
  // ============================================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================
  // SAVE USER TO LOCAL STORAGE
  // ============================================
  Future<void> _saveUserToLocal(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString('user', userJson);
    } catch (e) {
      print('Save user to local error: $e');
    }
  }

  // ============================================
  // CLEAR USER FROM LOCAL STORAGE
  // ============================================
  Future<void> _clearUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    } catch (e) {
      print('Clear user from local error: $e');
    }
  }
}
