import 'dart:convert';
import 'package:app_wallet/core/network/api_client.dart';
import 'package:app_wallet/data/models/transaction_model.dart';
import 'package:app_wallet/core/error/failures.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> getAllTransactions();
  Future<List<TransactionModel>> getUserTransactions(int userId);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient client;
  TransactionRemoteDataSourceImpl(this.client);

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final response = await client.get('/transactions');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    }
    throw const ServerFailure('Failed to load transactions');
  }

  @override
  Future<List<TransactionModel>> getUserTransactions(int userId) async {
    final response = await client.get('/transactions/$userId');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    }
    throw const ServerFailure('Failed to load UserEntity transactions');
  }
}
