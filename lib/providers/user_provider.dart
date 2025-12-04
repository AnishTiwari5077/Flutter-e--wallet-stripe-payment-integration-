import 'package:app_wallet/models/user_model.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  bool get isLoggedIn => _user != null;


  void setUser(User u) {
    _user = u;
    notifyListeners();
  }


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

  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }


  void logout() {
    _user = null;
    notifyListeners();
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
}
