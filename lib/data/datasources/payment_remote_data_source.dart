import 'dart:convert';
import 'package:app_wallet/core/network/api_client.dart';
import 'package:app_wallet/data/models/user_model.dart';
import 'package:app_wallet/core/error/failures.dart';

abstract class PaymentRemoteDataSource {
  Future<UserModel> processDeposit({
    required int userId,
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  });

  Future<bool> sendMoney({
    required int senderId,
    required String receiverPhone,
    required double amount,
  });

  Future<bool> bankTransfer({
    required int userId,
    required String accountNumber,
    required String bankName,
    required double amount,
  });

  Future<bool> collegePayment({
    required int userId,
    required String studentId,
    required String collegeName,
    required String semester,
    required double amount,
  });

  Future<bool> mobileTopup({
    required int userId,
    required String phoneNumber,
    required String operator,
    required double amount,
  });

  Future<bool> billPayment({
    required int userId,
    required String billType,
    required String accountNumber,
    required double amount,
  });

  Future<bool> shoppingPayment({
    required int userId,
    required String merchantName,
    required double amount,
    List<Map<String, dynamic>>? items,
  });
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient client;
  PaymentRemoteDataSourceImpl(this.client);

  @override
  Future<UserModel> processDeposit({
    required int userId,
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    final response = await client.post('/process-deposit', {
      'user_id': userId,
      'amount': amount,
      'card_number': cardNumber,
      'exp_month': expMonth,
      'exp_year': expYear,
      'cvc': cvc,
    });
    
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (body['user'] != null) {
        return UserModel.fromJson(body['user']);
      }
      throw const ServerFailure('Invalid UserEntity data received');
    }
    throw ServerFailure(body['error'] ?? 'Deposit failed');
  }

  @override
  Future<bool> sendMoney({
    required int senderId,
    required String receiverPhone,
    required double amount,
  }) async {
    final response = await client.post('/send', {
      'sender_id': senderId,
      'phone': receiverPhone,
      'amount': amount,
    });
    
    if (response.statusCode == 200) return true;
    final body = jsonDecode(response.body);
    throw ServerFailure(body['error'] ?? 'Send money failed');
  }

  @override
  Future<bool> bankTransfer({
    required int userId,
    required String accountNumber,
    required String bankName,
    required double amount,
  }) async {
    final response = await client.post('/bank-transfer', {
      'user_id': userId,
      'account_number': accountNumber,
      'bank_name': bankName,
      'amount': amount,
    });
    
    if (response.statusCode == 200) return true;
    final body = jsonDecode(response.body);
    throw ServerFailure(body['error'] ?? 'Bank transfer failed');
  }

  @override
  Future<bool> collegePayment({
    required int userId,
    required String studentId,
    required String collegeName,
    required String semester,
    required double amount,
  }) async {
    final response = await client.post('/college-payment', {
      'user_id': userId,
      'student_id': studentId,
      'college_name': collegeName,
      'semester': semester,
      'amount': amount,
    });
    
    if (response.statusCode == 200) return true;
    final body = jsonDecode(response.body);
    throw ServerFailure(body['error'] ?? 'College payment failed');
  }

  @override
  Future<bool> mobileTopup({
    required int userId,
    required String phoneNumber,
    required String operator,
    required double amount,
  }) async {
    final response = await client.post('/mobile-topup', {
      'user_id': userId,
      'phone_number': phoneNumber,
      'operator': operator,
      'amount': amount,
    });
    
    if (response.statusCode == 200) return true;
    final body = jsonDecode(response.body);
    throw ServerFailure(body['error'] ?? 'Mobile topup failed');
  }

  @override
  Future<bool> billPayment({
    required int userId,
    required String billType,
    required String accountNumber,
    required double amount,
  }) async {
    final response = await client.post('/bill-payment', {
      'user_id': userId,
      'bill_type': billType,
      'account_number': accountNumber,
      'amount': amount,
    });
    
    if (response.statusCode == 200) return true;
    final body = jsonDecode(response.body);
    throw ServerFailure(body['error'] ?? 'Bill payment failed');
  }

  @override
  Future<bool> shoppingPayment({
    required int userId,
    required String merchantName,
    required double amount,
    List<Map<String, dynamic>>? items,
  }) async {
    final response = await client.post('/shopping-payment', {
      'user_id': userId,
      'merchant_name': merchantName,
      'amount': amount,
      'items': items ?? [],
    });
    
    if (response.statusCode == 200) return true;
    final body = jsonDecode(response.body);
    throw ServerFailure(body['error'] ?? 'Shopping payment failed');
  }
}
