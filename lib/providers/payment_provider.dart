import 'package:app_wallet/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:app_wallet/services/payment_service.dart';

enum PaymentType {
  deposit,
  sendMoney,
  bankTransfer,
  collegePayment,
  topup,
  billPayment,
  shopping,
}

class PaymentProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

 
  Future<Map<String, dynamic>> depositMoney({
    required int userId,
    required double amount,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final result = await PaymentService.payWithPaymentSheet(
        amount: amount,
        userId: userId,
      );

      _setLoading(false);

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Deposit successful!';
        notifyListeners();
        
        return {
          'success': true,
          'message': _successMessage,
          'user': result['user'], // Pass updated user
        };
      } else {
        _errorMessage = result['message'] ?? 'Deposit failed';
        notifyListeners();
        return {'success': false, 'message': _errorMessage};
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Error: $e';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  Future<bool> sendMoney({
    required int senderId,
    required String receiverPhone,
    required double amount,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final result = await PaymentService.sendMoney(
        senderId: senderId,
        receiverPhone: receiverPhone,
        amount: amount,
      );

      _setLoading(false);

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Money sent successfully!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to send money';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }


  Future<bool> bankTransfer({
    required int userId,
    required String accountNumber,
    required String bankName,
    required double amount,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final result = await ApiService.bankTransfer(
        userId: userId,
        accountNumber: accountNumber,
        bankName: bankName,
        amount: amount,
      );

      _setLoading(false);

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Bank transfer successful!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Bank transfer failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Bank transfer failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> collegePayment({
    required int userId,
    required String studentId,
    required String collegeName,
    required double amount,
    required String semester,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final result = await ApiService.collegePayment(
        userId: userId,
        studentId: studentId,
        collegeName: collegeName,
        semester: semester,
        amount: amount,
      );

      _setLoading(false);

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'College payment successful!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'College payment failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'College payment failed: $e';
      notifyListeners();
      return false;
    }
  }


  Future<bool> mobileTopup({
    required int userId,
    required String phoneNumber,
    required String operator,
    required double amount,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final result = await ApiService.mobileTopup(
        userId: userId,
        phoneNumber: phoneNumber,
        operator: operator,
        amount: amount,
      );

      _setLoading(false);

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Mobile topup successful!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Mobile topup failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Mobile topup failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> billPayment({
    required int userId,
    required String billType,
    required String accountNumber,
    required double amount,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final result = await ApiService.billPayment(
        userId: userId,
        billType: billType,
        accountNumber: accountNumber,
        amount: amount,
      );

      _setLoading(false);

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Bill payment successful!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Bill payment failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Bill payment failed: $e';
      notifyListeners();
      return false;
    }
  }


  Future<bool> shoppingPayment({
    required int userId,
    required String merchantName,
    required double amount,
    required List<Map<String, dynamic>> items,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final result = await ApiService.shoppingPayment(
        userId: userId,
        merchantName: merchantName,
        amount: amount,
        items: items,
      );

      _setLoading(false);

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Shopping payment successful!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Shopping payment failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Shopping payment failed: $e';
      notifyListeners();
      return false;
    }
  }


  bool validateAmount(String amountText, {double? userBalance}) {
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _errorMessage = 'Please enter a valid amount';
      notifyListeners();
      return false;
    }

    if (userBalance != null && amount > userBalance) {
      _errorMessage =
          'Insufficient balance. Your balance: \$${userBalance.toStringAsFixed(2)}';
      notifyListeners();
      return false;
    }

    return true;
  }


  bool validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      _errorMessage = 'Please enter a phone number';
      notifyListeners();
      return false;
    }

    if (phone.length < 10) {
      _errorMessage = 'Please enter a valid phone number';
      notifyListeners();
      return false;
    }

    return true;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void clearMessages() {
    _clearMessages();
    notifyListeners();
  }

 
  String getPaymentTypeName(PaymentType type) {
    switch (type) {
      case PaymentType.deposit:
        return 'Deposit Money';
      case PaymentType.sendMoney:
        return 'Send Money';
      case PaymentType.bankTransfer:
        return 'Bank Transfer';
      case PaymentType.collegePayment:
        return 'College Payment';
      case PaymentType.topup:
        return 'Mobile Topup';
      case PaymentType.billPayment:
        return 'Bill Payment';
      case PaymentType.shopping:
        return 'Shopping';
    }
  }

 
  IconData getPaymentTypeIcon(PaymentType type) {
    switch (type) {
      case PaymentType.deposit:
        return Icons.add_circle_outline;
      case PaymentType.sendMoney:
        return Icons.send;
      case PaymentType.bankTransfer:
        return Icons.account_balance;
      case PaymentType.collegePayment:
        return Icons.school;
      case PaymentType.topup:
        return Icons.phone_android;
      case PaymentType.billPayment:
        return Icons.receipt_long;
      case PaymentType.shopping:
        return Icons.shopping_bag;
    }
  }

  Color getPaymentTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.deposit:
        return Colors.deepPurple;
      case PaymentType.sendMoney:
        return Colors.teal;
      case PaymentType.bankTransfer:
        return Colors.blue;
      case PaymentType.collegePayment:
        return Colors.orange;
      case PaymentType.topup:
        return Colors.green;
      case PaymentType.billPayment:
        return Colors.red;
      case PaymentType.shopping:
        return Colors.pink;
    }
  }
}
