import 'dart:io';
import 'package:intl/intl.dart';
import 'package:app_wallet/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.transactionId,
    required super.transactionType,
    required super.dateTime,
    required super.amount,
    super.status = 'Completed',
    super.senderId,
    super.senderName,
    super.senderEmail,
    super.senderPhone,
    super.receiverId,
    super.receiverName,
    super.receiverEmail,
    super.receiverPhone,
    super.bankName,
    super.accountNumber,
    super.collegeName,
    super.studentId,
    super.semester,
    super.phoneNumber,
    super.operator,
    super.billType,
    super.merchantName,
    super.processingFee,
    super.totalAmount,
    super.balanceBefore,
    super.balanceAfter,
    super.referenceNumber,
    super.description,
  });

  @override
  String get formattedDate => DateFormat('MMM dd, yyyy').format(dateTime);
  
  @override
  String get formattedTime => DateFormat('hh:mm a').format(dateTime);
  
  @override
  String get formattedDateTime =>
      DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);

  @override
  String get transactionTypeDisplay {
    switch (transactionType.toLowerCase()) {
      case 'add':
      case 'deposit':
        return 'Deposit';
      case 'send':
        return 'Money Transfer';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'college_payment':
        return 'College Fee Payment';
      case 'mobile_topup':
        return 'Mobile Recharge';
      case 'bill_payment':
        return 'Bill Payment';
      case 'shopping':
        return 'Shopping Payment';
      default:
        return 'Transaction';
    }
  }

  @override
  Map<String, String?> get details {
    final Map<String, String?> detailsMap = {};

    if (senderName != null) detailsMap['From'] = senderName;
    if (senderPhone != null) detailsMap['Sender Phone'] = senderPhone;
    if (receiverName != null) detailsMap['To'] = receiverName;
    if (receiverPhone != null) detailsMap['Receiver Phone'] = receiverPhone;
    if (bankName != null) detailsMap['Bank Name'] = bankName;
    if (accountNumber != null) detailsMap['Account Number'] = accountNumber;
    if (collegeName != null) detailsMap['College'] = collegeName;
    if (studentId != null) detailsMap['Student ID'] = studentId;
    if (semester != null) detailsMap['Semester'] = semester;
    if (phoneNumber != null) detailsMap['Phone Number'] = phoneNumber;
    if (operator != null) detailsMap['Operator'] = operator;
    if (billType != null) detailsMap['Bill Type'] = billType;
    if (merchantName != null) detailsMap['Merchant'] = merchantName;

    return detailsMap;
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final dateStr = json['created_at'] ?? json['date_time'];
      if (dateStr != null) {
        try {
          parsedDate = DateTime.parse(dateStr.toString());
        } catch (_) {
          // Fallback for RFC 1123 dates returned by Python Flask's jsonify
          try {
            parsedDate = HttpDate.parse(dateStr.toString());
          } catch (_) {
            parsedDate = DateTime.now();
          }
        }
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      transactionId: json['transaction_id']?.toString() ?? '',
      transactionType: json['type'] ?? '',
      dateTime: parsedDate,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'Completed',
      senderId: json['sender_id'] is int 
          ? json['sender_id'] 
          : int.tryParse(json['sender_id']?.toString() ?? ''),
      senderName: json['sender_name']?.toString(),
      senderEmail: json['sender_email']?.toString(),
      senderPhone: json['sender_phone']?.toString(),
      receiverId: json['receiver_id'] is int 
          ? json['receiver_id'] 
          : int.tryParse(json['receiver_id']?.toString() ?? ''),
      receiverName: json['receiver_name']?.toString(),
      receiverEmail: json['receiver_email']?.toString(),
      receiverPhone: json['receiver_phone']?.toString(),
      balanceBefore: double.tryParse(json['balance_before']?.toString() ?? '0'),
      balanceAfter: double.tryParse(json['balance_after']?.toString() ?? '0'),
      referenceNumber: json['reference_number']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'type': transactionType,
      'date_time': dateTime.toIso8601String(),
      'amount': amount,
      'status': status,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'receiver_id': receiverId,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'bank_name': bankName,
      'account_number': accountNumber,
      'college_name': collegeName,
      'student_id': studentId,
      'semester': semester,
      'phone_number': phoneNumber,
      'operator': operator,
      'bill_type': billType,
      'merchant_name': merchantName,
      'processing_fee': processingFee,
      'total_amount': totalAmount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'reference_number': referenceNumber,
      'description': description,
    };
  }
}
