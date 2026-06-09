import 'package:app_wallet/domain/entities/user_entity.dart';
import 'package:app_wallet/domain/repositories/payment_repository.dart';

class DepositUseCase {
  final PaymentRepository repository;
  DepositUseCase(this.repository);
  Future<UserEntity?> call({
    required int userId,
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
    required String idempotencyKey,
  }) => repository.processDeposit(
    userId: userId,
    amount: amount,
    cardNumber: cardNumber,
    expMonth: expMonth,
    expYear: expYear,
    cvc: cvc,
    idempotencyKey: idempotencyKey,
  );
}

class SendMoneyUseCase {
  final PaymentRepository repository;
  SendMoneyUseCase(this.repository);
  Future<bool> call({
    required int senderId,
    required String receiverPhone,
    required double amount,
    required String idempotencyKey,
  }) => repository.sendMoney(
    senderId: senderId,
    receiverPhone: receiverPhone,
    amount: amount,
    idempotencyKey: idempotencyKey,
  );
}

class BankTransferUseCase {
  final PaymentRepository repository;
  BankTransferUseCase(this.repository);
  Future<bool> call({
    required int userId,
    required String accountNumber,
    required String bankName,
    required double amount,
    required String idempotencyKey,
  }) => repository.bankTransfer(
    userId: userId,
    accountNumber: accountNumber,
    bankName: bankName,
    amount: amount,
    idempotencyKey: idempotencyKey,
  );
}

class CollegePaymentUseCase {
  final PaymentRepository repository;
  CollegePaymentUseCase(this.repository);
  Future<bool> call({
    required int userId,
    required String studentId,
    required String collegeName,
    required String semester,
    required double amount,
    required String idempotencyKey,
  }) => repository.collegePayment(
    userId: userId,
    studentId: studentId,
    collegeName: collegeName,
    semester: semester,
    amount: amount,
    idempotencyKey: idempotencyKey,
  );
}

class MobileTopupUseCase {
  final PaymentRepository repository;
  MobileTopupUseCase(this.repository);
  Future<bool> call({
    required int userId,
    required String phoneNumber,
    required String operator,
    required double amount,
    required String idempotencyKey,
  }) => repository.mobileTopup(
    userId: userId,
    phoneNumber: phoneNumber,
    operator: operator,
    amount: amount,
    idempotencyKey: idempotencyKey,
  );
}

class BillPaymentUseCase {
  final PaymentRepository repository;
  BillPaymentUseCase(this.repository);
  Future<bool> call({
    required int userId,
    required String billType,
    required String accountNumber,
    required double amount,
    required String idempotencyKey,
  }) => repository.billPayment(
    userId: userId,
    billType: billType,
    accountNumber: accountNumber,
    amount: amount,
    idempotencyKey: idempotencyKey,
  );
}

class ShoppingPaymentUseCase {
  final PaymentRepository repository;
  ShoppingPaymentUseCase(this.repository);
  Future<bool> call({
    required int userId,
    required String merchantName,
    required double amount,
    required String idempotencyKey,
    List<Map<String, dynamic>>? items,
  }) => repository.shoppingPayment(
    userId: userId,
    merchantName: merchantName,
    amount: amount,
    idempotencyKey: idempotencyKey,
    items: items,
  );
}
