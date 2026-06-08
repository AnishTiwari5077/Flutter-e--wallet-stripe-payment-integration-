import 'package:app_wallet/domain/entities/transaction_entity.dart';
import 'package:app_wallet/domain/repositories/transaction_repository.dart';

class GetAllTransactionsUseCase {
  final TransactionRepository repository;
  GetAllTransactionsUseCase(this.repository);
  Future<List<TransactionEntity>> call() => repository.getAllTransactions();
}

class GetUserTransactionsUseCase {
  final TransactionRepository repository;
  GetUserTransactionsUseCase(this.repository);
  Future<List<TransactionEntity>> call(int userId) =>
      repository.getUserTransactions(userId);
}
