import 'package:app_wallet/models/user_model.dart';
import 'package:app_wallet/services/api_services.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _loading = false;

  User? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    final u = await ApiService.login(email, password);
    _user = u;
    _loading = false;
    notifyListeners();
    return u != null;
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    String phone = '',
    String avatar = '',
  }) async {
    _loading = true;
    notifyListeners();

    final u = await ApiService.register(
      name,
      email,
      password,
      phone: phone,
      avatar: avatar,
    );
    _user = u;
    _loading = false;
    notifyListeners();
    return u != null;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    final u = await ApiService.fetchUser(_user!.email);
    if (u != null) {
      _user = u;
      notifyListeners();
    }
  }
}
