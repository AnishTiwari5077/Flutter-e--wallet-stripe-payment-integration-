class TransactionEntity {
  final String transactionId;
  final String transactionType;
  final DateTime dateTime;
  final double amount;
  final String status;

  final int? senderId;
  final String? senderName;
  final String? senderEmail;
  final String? senderPhone;

  final int? receiverId;
  final String? receiverName;
  final String? receiverEmail;
  final String? receiverPhone;

  final String? bankName;
  final String? accountNumber;
  final String? collegeName;
  final String? studentId;
  final String? semester;
  final String? phoneNumber;
  final String? operator;
  final String? billType;
  final String? merchantName;

  final double? processingFee;
  final double? totalAmount;

  final double? balanceBefore;
  final double? balanceAfter;

  final String? referenceNumber;
  final String? description;

  const TransactionEntity({
    required this.transactionId,
    required this.transactionType,
    required this.dateTime,
    required this.amount,
    this.status = 'Completed',
    this.senderId,
    this.senderName,
    this.senderEmail,
    this.senderPhone,
    this.receiverId,
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

  String get formattedDate {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  String get formattedTime {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String get formattedDateTime {
    return "$formattedDate $formattedTime";
  }

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
}
