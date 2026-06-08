import 'package:flutter/material.dart';
import 'package:app_wallet/domain/entities/transaction_entity.dart';
import 'package:app_wallet/domain/usecases/transaction_usecases.dart';

class TransactionProvider with ChangeNotifier {
  final GetAllTransactionsUseCase getAllTransactionsUseCase;
  final GetUserTransactionsUseCase getUserTransactionsUseCase;

  TransactionProvider({
    required this.getAllTransactionsUseCase,
    required this.getUserTransactionsUseCase,
  });

  List<TransactionEntity> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionEntity> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserTransactions(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await getUserTransactionsUseCase.call(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAllTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await getAllTransactionsUseCase.call();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  List<TransactionEntity> getTransactionsByType(String type) {
    return _transactions.where((t) => t.transactionType == type).toList();
  }

  List<TransactionEntity> getSentTransactions(int userId) {
    return _transactions
        .where((t) => t.senderEmail != null && t.transactionType == 'send') // Note: Using senderEmail as proxy for sender_id check depending on backend return. In an ideal world, ID would be there.
        .toList();
  }

  List<TransactionEntity> getReceivedTransactions(int userId) {
    return _transactions
        .where((t) => t.receiverEmail != null && t.transactionType == 'send')
        .toList();
  }

  List<TransactionEntity> getDepositTransactions(int userId) {
    return _transactions
        .where((t) => t.transactionType == 'add' || t.transactionType == 'deposit')
        .toList();
  }

  double getTotalSent(int userId) {
    return getSentTransactions(userId).fold(
      0.0,
      (sum, t) => sum + t.amount,
    );
  }

  double getTotalReceived(int userId) {
    return getReceivedTransactions(userId).fold(
      0.0,
      (sum, t) => sum + t.amount,
    );
  }

  double getTotalDeposits(int userId) {
    return getDepositTransactions(userId).fold(
      0.0,
      (sum, t) => sum + t.amount,
    );
  }

  Future<void> refreshTransactions(int userId) async {
    await fetchUserTransactions(userId);
  }

  void clearTransactions() {
    _transactions = [];
    _errorMessage = null;
    notifyListeners();
  }
}
