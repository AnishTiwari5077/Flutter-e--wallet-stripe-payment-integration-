import 'package:app_wallet/domain/entities/user_entity.dart';

abstract class PaymentRepository {
  Future<UserEntity?> processDeposit({
    required int userId,
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
    required String idempotencyKey,
  });

  Future<bool> sendMoney({
    required int senderId,
    required String receiverPhone,
    required double amount,
    required String idempotencyKey,
  });

  Future<bool> bankTransfer({
    required int userId,
    required String accountNumber,
    required String bankName,
    required double amount,
    required String idempotencyKey,
  });

  Future<bool> collegePayment({
    required int userId,
    required String studentId,
    required String collegeName,
    required String semester,
    required double amount,
    required String idempotencyKey,
  });

  Future<bool> mobileTopup({
    required int userId,
    required String phoneNumber,
    required String operator,
    required double amount,
    required String idempotencyKey,
  });

  Future<bool> billPayment({
    required int userId,
    required String billType,
    required String accountNumber,
    required double amount,
    required String idempotencyKey,
  });

  Future<bool> shoppingPayment({
    required int userId,
    required String merchantName,
    required double amount,
    required String idempotencyKey,
    List<Map<String, dynamic>>? items,
  });
}
