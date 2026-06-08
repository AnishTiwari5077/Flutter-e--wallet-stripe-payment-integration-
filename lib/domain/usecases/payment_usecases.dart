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
  }) => repository.processDeposit(
    userId: userId,
    amount: amount,
    cardNumber: cardNumber,
    expMonth: expMonth,
    expYear: expYear,
    cvc: cvc,
  );
}

class SendMoneyUseCase {
  final PaymentRepository repository;
  SendMoneyUseCase(this.repository);
  Future<bool> call({
    required int senderId,
    required String receiverPhone,
    required double amount,
  }) => repository.sendMoney(
    senderId: senderId,
    receiverPhone: receiverPhone,
    amount: amount,
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
  }) => repository.bankTransfer(
    userId: userId,
    accountNumber: accountNumber,
    bankName: bankName,
    amount: amount,
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
  }) => repository.collegePayment(
    userId: userId,
    studentId: studentId,
    collegeName: collegeName,
    semester: semester,
    amount: amount,
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
  }) => repository.mobileTopup(
    userId: userId,
    phoneNumber: phoneNumber,
    operator: operator,
    amount: amount,
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
  }) => repository.billPayment(
    userId: userId,
    billType: billType,
    accountNumber: accountNumber,
    amount: amount,
  );
}

class ShoppingPaymentUseCase {
  final PaymentRepository repository;
  ShoppingPaymentUseCase(this.repository);
  Future<bool> call({
    required int userId,
    required String merchantName,
    required double amount,
    List<Map<String, dynamic>>? items,
  }) => repository.shoppingPayment(
    userId: userId,
    merchantName: merchantName,
    amount: amount,
    items: items,
  );
}
