// lib/models/transaction_receipt_model.dart
import 'package:intl/intl.dart';

class TransactionReceipt {
  final String transactionId;
  final String transactionType;
  final DateTime dateTime;
  final double amount;
  final String status;

  // Sender information
  final String? senderName;
  final String? senderEmail;
  final String? senderPhone;

  // Receiver information
  final String? receiverName;
  final String? receiverEmail;
  final String? receiverPhone;

  // Additional details
  final String? bankName;
  final String? accountNumber;
  final String? collegeName;
  final String? studentId;
  final String? semester;
  final String? phoneNumber;
  final String? operator;
  final String? billType;
  final String? merchantName;

  // Fees and totals
  final double? processingFee;
  final double? totalAmount;

  // Balance information
  final double? balanceBefore;
  final double? balanceAfter;

  // Reference
  final String? referenceNumber;
  final String? description;

  TransactionReceipt({
    required this.transactionId,
    required this.transactionType,
    required this.dateTime,
    required this.amount,
    this.status = 'Completed',
    this.senderName,
    this.senderEmail,
    this.senderPhone,
    this.receiverName,
    this.receiverEmail,
    this.receiverPhone,
    this.bankName,
    this.accountNumber,
    this.collegeName,
    this.studentId,
    this.semester,
    this.phoneNumber,
    this.operator,
    this.billType,
    this.merchantName,
    this.processingFee,
    this.totalAmount,
    this.balanceBefore,
    this.balanceAfter,
    this.referenceNumber,
    this.description,
  });

  // Format date
  String get formattedDate => DateFormat('MMM dd, yyyy').format(dateTime);
  String get formattedTime => DateFormat('hh:mm a').format(dateTime);
  String get formattedDateTime =>
      DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);

  // Get transaction type display name
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

  // Get transaction details as map
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

  // Create from JSON
  factory TransactionReceipt.fromJson(Map<String, dynamic> json) {
    return TransactionReceipt(
      transactionId: json['transaction_id']?.toString() ?? '',
      transactionType: json['type'] ?? '',
      dateTime: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'Completed',
      senderName: json['sender_name'],
      senderEmail: json['sender_email'],
      senderPhone: json['sender_phone'],
      receiverName: json['receiver_name'],
      receiverEmail: json['receiver_email'],
      receiverPhone: json['receiver_phone'],
      balanceBefore: double.tryParse(json['balance_before']?.toString() ?? '0'),
      balanceAfter: double.tryParse(json['balance_after']?.toString() ?? '0'),
      referenceNumber: json['reference_number'],
      description: json['description'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'type': transactionType,
      'date_time': dateTime.toIso8601String(),
      'amount': amount,
      'status': status,
      'sender_name': senderName,
      'sender_phone': senderPhone,
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
