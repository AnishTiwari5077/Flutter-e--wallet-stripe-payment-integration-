import 'package:app_wallet/services/api_services.dart';
import 'package:flutter/material.dart';

class TransactionProvider with ChangeNotifier {
  List<dynamic> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ============================================
  // FETCH USER TRANSACTIONS
  // ============================================
  Future<void> fetchUserTransactions(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.getUserTransactions(userId);
      _transactions = data;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load transactions: $e';
      notifyListeners();
    }
  }

  // ============================================
  // FETCH ALL TRANSACTIONS (Admin)
  // ============================================
  Future<void> fetchAllTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.getAllTransactions();
      _transactions = data;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load transactions: $e';
      notifyListeners();
    }
  }

  // ============================================
  // FILTER TRANSACTIONS BY TYPE
  // ============================================
  List<dynamic> getTransactionsByType(String type) {
    return _transactions.where((t) => t['type'] == type).toList();
  }

  // ============================================
  // GET SENT TRANSACTIONS
  // ============================================
  List<dynamic> getSentTransactions(int userId) {
    return _transactions
        .where((t) => t['sender_id'] == userId && t['type'] == 'send')
        .toList();
  }

  // ============================================
  // GET RECEIVED TRANSACTIONS
  // ============================================
  List<dynamic> getReceivedTransactions(int userId) {
    return _transactions
        .where((t) => t['receiver_id'] == userId && t['type'] == 'send')
        .toList();
  }

  // ============================================
  // GET DEPOSIT TRANSACTIONS
  // ============================================
  List<dynamic> getDepositTransactions(int userId) {
    return _transactions
        .where((t) => t['receiver_id'] == userId && t['type'] == 'add')
        .toList();
  }

  // ============================================
  // CALCULATE TOTAL SENT
  // ============================================
  double getTotalSent(int userId) {
    return getSentTransactions(userId).fold(
      0.0,
      (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0.0),
    );
  }

  // ============================================
  // CALCULATE TOTAL RECEIVED
  // ============================================
  double getTotalReceived(int userId) {
    return getReceivedTransactions(userId).fold(
      0.0,
      (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0.0),
    );
  }

  // ============================================
  // CALCULATE TOTAL DEPOSITS
  // ============================================
  double getTotalDeposits(int userId) {
    return getDepositTransactions(userId).fold(
      0.0,
      (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0.0),
    );
  }

  // ============================================
  // REFRESH TRANSACTIONS
  // ============================================
  Future<void> refreshTransactions(int userId) async {
    await fetchUserTransactions(userId);
  }

  // ============================================
  // CLEAR TRANSACTIONS
  // ============================================
  void clearTransactions() {
    _transactions = [];
    _errorMessage = null;
    notifyListeners();
  }
}
