import 'package:app_wallet/domain/entities/transaction_entity.dart';
import 'package:app_wallet/domain/repositories/transaction_repository.dart';
import 'package:app_wallet/data/datasources/transaction_remote_data_source.dart';
import 'package:app_wallet/core/error/failures.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    try {
      return await remoteDataSource.getAllTransactions();
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<TransactionEntity>> getUserTransactions(int userId) async {
    try {
      return await remoteDataSource.getUserTransactions(userId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
