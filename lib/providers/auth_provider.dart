import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_wallet/models/user_model.dart';
import 'package:app_wallet/services/api_services.dart';

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
    await _clearUserFromLocal();
    notifyListeners();
  }

  // ============================================
  // REFRESH USER DATA (Optimized)
  // ============================================
  Future<void> refreshUser() async {
    if (_user?.id == null) return;

    try {
      final freshUser = await ApiService.fetchUser(_user!.id!);

      // Only update if any user field changed
      if (freshUser != null &&
          (freshUser.name != _user!.name ||
              freshUser.balance != _user!.balance ||
              freshUser.email != _user!.email ||
              freshUser.phone != _user!.phone ||
              freshUser.avatar != _user!.avatar)) {
        _user = freshUser;
        await _saveUserToLocal(_user!);
        notifyListeners();
      }
    } catch (e) {
      print('Refresh user error: $e');
    }
  }

  // ============================================
  // CHECK AUTH STATUS (Optimized)
  // ============================================
  Future<bool> checkAuthStatus() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        final localUser = User.fromJson(userMap);

        bool needsUpdate = false;

        // Only refresh user if local data is different
        if (_user == null || _user!.id != localUser.id) {
          _user = localUser;
          needsUpdate = true;
        }

        if (_user?.id != null) {
          await refreshUser(); // Refresh from server if necessary
        }

        _loading = false;
        if (needsUpdate) notifyListeners();
        return true;
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
  // UPDATE BALANCE & USER
  // ============================================
  void updateBalance(double newBalance) {
    if (_user != null) {
      final updatedUser = _user!.copyWith(balance: newBalance);
      _updateUser(updatedUser);
    }
  }

  void updateUser(User updatedUser) {
    _updateUser(updatedUser);
  }

  void addMoney(double amount) {
    if (_user != null) updateBalance(_user!.balance + amount);
  }

  void deductMoney(double amount) {
    if (_user != null && _user!.balance >= amount)
      updateBalance(_user!.balance - amount);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================
  void _updateUser(User updatedUser) {
    if (_user != updatedUser) {
      _user = updatedUser;
      _saveUserToLocal(_user!);
      notifyListeners();
    }
  }

  Future<void> _saveUserToLocal(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
    } catch (e) {
      print('Save user to local error: $e');
    }
  }

  Future<void> _clearUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    } catch (e) {
      print('Clear user from local error: $e');
    }
  }
}
