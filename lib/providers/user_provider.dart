import 'package:app_wallet/models/user_model.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  // Set user after login/registration
  void setUser(User u) {
    _user = u;
    notifyListeners();
  }

  // Update user balance
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
      notifyListeners();
    }
  }

  // Update entire user object
  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  // Logout
  void logout() {
    _user = null;
    notifyListeners();
  }

  // Add money to balance
  void addMoney(double amount) {
    if (_user != null) {
      updateBalance(_user!.balance + amount);
    }
  }

  // Deduct money from balance
  void deductMoney(double amount) {
    if (_user != null && _user!.balance >= amount) {
      updateBalance(_user!.balance - amount);
    }
  }
}
