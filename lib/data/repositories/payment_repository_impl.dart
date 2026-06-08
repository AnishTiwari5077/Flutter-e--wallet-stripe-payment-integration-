import 'package:app_wallet/domain/entities/user_entity.dart';
import 'package:app_wallet/domain/repositories/payment_repository.dart';
import 'package:app_wallet/data/datasources/payment_remote_data_source.dart';
import 'package:app_wallet/core/error/failures.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> processDeposit({
    required int userId,
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    try {
      return await remoteDataSource.processDeposit(
        userId: userId,
        amount: amount,
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<bool> sendMoney({
    required int senderId,
    required String receiverPhone,
    required double amount,
  }) async {
    try {
      return await remoteDataSource.sendMoney(
        senderId: senderId,
        receiverPhone: receiverPhone,
        amount: amount,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<bool> bankTransfer({
    required int userId,
    required String accountNumber,
    required String bankName,
    required double amount,
  }) async {
    try {
      return await remoteDataSource.bankTransfer(
        userId: userId,
        accountNumber: accountNumber,
        bankName: bankName,
        amount: amount,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<bool> collegePayment({
    required int userId,
    required String studentId,
    required String collegeName,
    required String semester,
    required double amount,
  }) async {
    try {
      return await remoteDataSource.collegePayment(
        userId: userId,
        studentId: studentId,
        collegeName: collegeName,
        semester: semester,
        amount: amount,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<bool> mobileTopup({
    required int userId,
    required String phoneNumber,
    required String operator,
    required double amount,
  }) async {
    try {
      return await remoteDataSource.mobileTopup(
        userId: userId,
        phoneNumber: phoneNumber,
        operator: operator,
        amount: amount,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<bool> billPayment({
    required int userId,
    required String billType,
    required String accountNumber,
    required double amount,
  }) async {
    try {
      return await remoteDataSource.billPayment(
        userId: userId,
        billType: billType,
        accountNumber: accountNumber,
        amount: amount,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<bool> shoppingPayment({
    required int userId,
    required String merchantName,
    required double amount,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      return await remoteDataSource.shoppingPayment(
        userId: userId,
        merchantName: merchantName,
        amount: amount,
        items: items,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
