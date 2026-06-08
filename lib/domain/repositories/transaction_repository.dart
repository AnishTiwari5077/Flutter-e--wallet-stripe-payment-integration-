import 'package:app_wallet/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getAllTransactions();
  Future<List<TransactionEntity>> getUserTransactions(int userId);
}
