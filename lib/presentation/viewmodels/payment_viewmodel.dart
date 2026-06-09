import 'package:flutter/material.dart';
import 'package:app_wallet/domain/usecases/payment_usecases.dart';
import 'package:app_wallet/core/error/failures.dart';

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
  final DepositUseCase depositUseCase;
  final SendMoneyUseCase sendMoneyUseCase;
  final BankTransferUseCase bankTransferUseCase;
  final CollegePaymentUseCase collegePaymentUseCase;
  final MobileTopupUseCase mobileTopupUseCase;
  final BillPaymentUseCase billPaymentUseCase;
  final ShoppingPaymentUseCase shoppingPaymentUseCase;

  PaymentProvider({
    required this.depositUseCase,
    required this.sendMoneyUseCase,
    required this.bankTransferUseCase,
    required this.collegePaymentUseCase,
    required this.mobileTopupUseCase,
    required this.billPaymentUseCase,
    required this.shoppingPaymentUseCase,
  });

  bool _isLoading = false;
  bool _isProcessing = false; // Guard against concurrent payment requests
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<Map<String, dynamic>> depositMoney({
    required int userId,
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
    required String idempotencyKey,
  }) async {
    // Hard guard — reject if a payment is already in flight
    if (_isProcessing) {
      return {'success': false, 'message': 'A payment is already being processed. Please wait.'};
    }

    _isProcessing = true;
    _setLoading(true);
    _clearMessages();

    try {
      final user = await depositUseCase.call(
        userId: userId,
        amount: amount,
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        idempotencyKey: idempotencyKey,
      );
      _successMessage = 'Deposit successful!';
      notifyListeners();
      return {'success': true, 'message': _successMessage, 'user': user};
    } catch (e) {
      if (e is NetworkFailure) {
        // Safe to retry — the same session key prevents double-charging.
        _errorMessage = 'Network error. Your card may not have been charged. '
            'You can safely tap retry — no double charge will occur.';
      } else if (e is Failure) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    } finally {
      _isProcessing = false;
      _setLoading(false);
    }
  }

  Future<bool> sendMoney({
    required int senderId,
    required String receiverPhone,
    required double amount,
    required String idempotencyKey,
  }) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _setLoading(true);
    _clearMessages();

    try {
      await sendMoneyUseCase.call(
        senderId: senderId,
        receiverPhone: receiverPhone,
        amount: amount,
        idempotencyKey: idempotencyKey,
      );
      _successMessage = 'Money sent successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      if (e is Failure) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      _setLoading(false);
    }
  }

  Future<bool> bankTransfer({
    required int userId,
    required String accountNumber,
    required String bankName,
    required double amount,
    required String idempotencyKey,
  }) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _setLoading(true);
    _clearMessages();

    try {
      await bankTransferUseCase.call(
        userId: userId,
        accountNumber: accountNumber,
        bankName: bankName,
        amount: amount,
        idempotencyKey: idempotencyKey,
      );
      _successMessage = 'Bank transfer successful!';
      notifyListeners();
      return true;
    } catch (e) {
      if (e is Failure) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      _setLoading(false);
    }
  }

  Future<bool> collegePayment({
    required int userId,
    required String studentId,
    required String collegeName,
    required double amount,
    required String semester,
    required String idempotencyKey,
  }) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _setLoading(true);
    _clearMessages();

    try {
      await collegePaymentUseCase.call(
        userId: userId,
        studentId: studentId,
        collegeName: collegeName,
        semester: semester,
        amount: amount,
        idempotencyKey: idempotencyKey,
      );
      _successMessage = 'College payment successful!';
      notifyListeners();
      return true;
    } catch (e) {
      if (e is Failure) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      _setLoading(false);
    }
  }

  Future<bool> mobileTopup({
    required int userId,
    required String phoneNumber,
    required String operator,
    required double amount,
    required String idempotencyKey,
  }) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _setLoading(true);
    _clearMessages();

    try {
      await mobileTopupUseCase.call(
        userId: userId,
        phoneNumber: phoneNumber,
        operator: operator,
        amount: amount,
        idempotencyKey: idempotencyKey,
      );
      _successMessage = 'Mobile topup successful!';
      notifyListeners();
      return true;
    } catch (e) {
      if (e is Failure) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      _setLoading(false);
    }
  }

  Future<bool> billPayment({
    required int userId,
    required String billType,
    required String accountNumber,
    required double amount,
    required String idempotencyKey,
  }) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _setLoading(true);
    _clearMessages();

    try {
      await billPaymentUseCase.call(
        userId: userId,
        billType: billType,
        accountNumber: accountNumber,
        amount: amount,
        idempotencyKey: idempotencyKey,
      );
      _successMessage = 'Bill payment successful!';
      notifyListeners();
      return true;
    } catch (e) {
      if (e is Failure) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      _setLoading(false);
    }
  }

  Future<bool> shoppingPayment({
    required int userId,
    required String merchantName,
    required double amount,
    required String idempotencyKey,
    required List<Map<String, dynamic>> items,
  }) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _setLoading(true);
    _clearMessages();

    try {
      await shoppingPaymentUseCase.call(
        userId: userId,
        merchantName: merchantName,
        amount: amount,
        idempotencyKey: idempotencyKey,
        items: items,
      );
      _successMessage = 'Shopping payment successful!';
      notifyListeners();
      return true;
    } catch (e) {
      if (e is Failure) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      _setLoading(false);
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
      _errorMessage = 'Insufficient balance. Your balance: \$${userBalance.toStringAsFixed(2)}';
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
      case PaymentType.deposit: return 'Deposit Money';
      case PaymentType.sendMoney: return 'Send Money';
      case PaymentType.bankTransfer: return 'Bank Transfer';
      case PaymentType.collegePayment: return 'College Payment';
      case PaymentType.topup: return 'Mobile Topup';
      case PaymentType.billPayment: return 'Bill Payment';
      case PaymentType.shopping: return 'Shopping';
    }
  }

  IconData getPaymentTypeIcon(PaymentType type) {
    switch (type) {
      case PaymentType.deposit: return Icons.add_circle_outline;
      case PaymentType.sendMoney: return Icons.send;
      case PaymentType.bankTransfer: return Icons.account_balance;
      case PaymentType.collegePayment: return Icons.school;
      case PaymentType.topup: return Icons.phone_android;
      case PaymentType.billPayment: return Icons.receipt_long;
      case PaymentType.shopping: return Icons.shopping_bag;
    }
  }

  Color getPaymentTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.deposit: return Colors.deepPurple;
      case PaymentType.sendMoney: return Colors.teal;
      case PaymentType.bankTransfer: return Colors.blue;
      case PaymentType.collegePayment: return Colors.orange;
      case PaymentType.topup: return Colors.green;
      case PaymentType.billPayment: return Colors.red;
      case PaymentType.shopping: return Colors.pink;
    }
  }
}
