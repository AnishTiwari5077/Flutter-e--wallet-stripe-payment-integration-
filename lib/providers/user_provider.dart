import 'package:app_wallet/models/user_model.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

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
}
