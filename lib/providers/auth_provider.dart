import 'package:app_wallet/models/user_model.dart';

import 'package:app_wallet/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  // ============================================
  // LOGIN - Updated to work with new API format
  // ============================================
  Future<bool> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // New API returns Map<String, dynamic> with 'success' and 'user'
      final result = await ApiService.login(email, password);

      if (result['success'] == true && result['user'] != null) {
        _user = result['user'];

        // Save user to local storage
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
  // REGISTER - Updated to work with new API format
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
      // New API returns Map<String, dynamic> with 'success' and 'user'
      final result = await ApiService.register(
        name,
        email,
        password,
        phone: phone,
        avatar: avatar,
      );

      if (result['success'] == true && result['user'] != null) {
        _user = result['user'];

        // Optionally save user to local storage after registration
        // await _saveUserToLocal(_user!);

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

    // Clear from local storage
    await _clearUserFromLocal();

    notifyListeners();
  }

  // ============================================
  // REFRESH USER DATA
  // ============================================
  Future<void> refreshUser() async {
    if (_user?.id == null) return;

    try {
      // Use user ID instead of email
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
  // CHECK AUTH STATUS (Auto-login)
  // ============================================
  Future<bool> checkAuthStatus() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        _user = User.fromJson(userMap);

        // Optional: Refresh user data from server
        if (_user?.id != null) {
          await refreshUser();
        }

        _loading = false;
        notifyListeners();
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
  // UPDATE USER BALANCE
  // ============================================
  void updateBalance(double newBalance) {
    if (_user != null) {
      _user = User(
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

  // ============================================
  // UPDATE ENTIRE USER
  // ============================================
  void updateUser(User updatedUser) {
    _user = updatedUser;
    _saveUserToLocal(updatedUser);
    notifyListeners();
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
  // CLEAR ERROR MESSAGE
  // ============================================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================
  // PRIVATE: SAVE USER TO LOCAL STORAGE
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
  // PRIVATE: CLEAR USER FROM LOCAL STORAGE
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

// ============================================
// USAGE EXAMPLES
// ============================================
/*
// In Login Screen:
final authProvider = Provider.of<AuthProvider>(context, listen: false);

final success = await authProvider.login(email, password);

if (success) {
  Navigator.pushReplacementNamed(context, '/home');
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(authProvider.errorMessage ?? 'Login failed'),
      backgroundColor: Colors.red,
    ),
  );
}

// In Register Screen:
final authProvider = Provider.of<AuthProvider>(context, listen: false);

final success = await authProvider.register(name, email, password, phone: phone);

if (success) {
  // User registered successfully, navigate to login
  Navigator.pushReplacementNamed(context, '/login');
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(authProvider.errorMessage ?? 'Registration failed'),
      backgroundColor: Colors.red,
    ),
  );
}

// Show loading indicator:
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    if (authProvider.loading) {
      return CircularProgressIndicator();
    }
    return ElevatedButton(
      onPressed: () => _handleLogin(),
      child: Text('Login'),
    );
  },
)

// In Main.dart for auto-login:
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            home: FutureBuilder(
              future: authProvider.checkAuthStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (authProvider.isAuthenticated) {
                  return HomeScreen();
                }
                
                return LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
*/
