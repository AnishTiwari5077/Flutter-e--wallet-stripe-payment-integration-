import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_wallet/models/user_model.dart';
import 'package:app_wallet/services/api_services.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _errorMessage;

  // ============================================
  // Getters
  // ============================================
  User? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  // ============================================
  // Core Authentication Methods
  // ============================================

  /// Logs in the user and saves their data locally.
  Future<bool> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password);

      if (result['success'] == true && result['user'] != null) {
        _user = result['user'];
        await _saveUserToLocal(_user!);
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Login failed';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Registers a new user.
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
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clears user data and local storage, triggering a rebuild to a logged-out state.
  Future<void> logout() async {
    _user = null;
    _errorMessage = null;
    await _clearUserFromLocal();
    notifyListeners();
  }

  // ============================================
  // Auth Status & Data Management
  // ============================================

  /// Checks local storage for a user and attempts to refresh data from the server.
  Future<bool> checkAuthStatus() async {
    _loading = true;
    notifyListeners(); // Show loading state

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        try {
          final userMap = jsonDecode(userJson);
          final localUser = User.fromJson(userMap);

          // 1. Set user from local storage
          _user = localUser;

          // 2. Refresh from server only if we have a valid ID
          if (_user?.id != null) {
            await refreshUser(fetchFromServer: true);
          }

          // Return true if we successfully loaded any user data
          return true;
        } catch (e) {
          // ⚠️ CATCHES _TypeError from corrupted local JSON data
          print(
            'Error parsing local user data. Clearing local storage. Error: $e',
          );
          await _clearUserFromLocal();
          _user = null;
        }
      }

      return false; // No user data found locally or data was corrupt
    } catch (e) {
      print('Check auth status error: $e');
      _user = null;
      return false;
    } finally {
      // ✅ GUARANTEED STATE RESET: Always stops the loading indicator
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetches the latest user data from the server.
  Future<void> refreshUser({bool fetchFromServer = false}) async {
    // ⚠️ NULL SAFETY: Safely extract ID before using it
    final userId = _user?.id;
    if (userId == null) return;

    if (!fetchFromServer) {
      return;
    }

    try {
      // ⚠️ Use the safely extracted ID
      final freshUser = await ApiService.fetchUser(userId);

      // Only update if fresh data is received AND it's actually different
      if (freshUser != null && freshUser != _user) {
        _user = freshUser;
        await _saveUserToLocal(_user!);
        notifyListeners(); // Notify if user data changed
      }
    } catch (e) {
      print('Refresh user error: $e');
    }
  }

  // ============================================
  // State Mutators
  // ============================================

  /// Updates the user's balance and saves the change.
  void updateBalance(double newBalance) {
    if (_user != null) {
      final updatedUser = _user!.copyWith(balance: newBalance);
      _updateUser(updatedUser);
    }
  }

  /// Replaces the current user object with a new one.
  void updateUser(User updatedUser) {
    _updateUser(updatedUser);
  }

  /// Adds an amount to the user's balance.
  void addMoney(double amount) {
    if (_user != null) updateBalance(_user!.balance + amount);
  }

  /// Deducts an amount from the user's balance.
  void deductMoney(double amount) {
    if (_user != null && _user!.balance >= amount) {
      updateBalance(_user!.balance - amount);
    }
  }

  /// Clears the last error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================
  // Private Helpers (Separating concerns)
  // ============================================

  /// Internal method to update the user object, save it, and notify.
  void _updateUser(User updatedUser) {
    if (_user != updatedUser) {
      _user = updatedUser;
      _saveUserToLocal(_user!);
      notifyListeners();
    }
  }

  /// Saves the current user object to SharedPreferences.
  Future<void> _saveUserToLocal(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
    } catch (e) {
      print('Save user to local error: $e');
    }
  }

  /// Clears the user object from SharedPreferences.
  Future<void> _clearUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    } catch (e) {
      print('Clear user from local error: $e');
    }
  }
}
