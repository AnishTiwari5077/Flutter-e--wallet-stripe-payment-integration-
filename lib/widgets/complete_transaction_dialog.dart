import 'package:flutter/material.dart';

/// Transaction types for the confirmation dialog
enum TransactionType {
  deposit,
  sendMoney,
  bankTransfer,
  collegePayment,
  mobileTopup,
  billPayment,
  shopping,
}

/// Transaction Confirmation Dialog
/// Shows a beautiful confirmation dialog before any transaction
class TransactionConfirmationDialog extends StatelessWidget {
  final TransactionType type;
  final double amount;
  final Map<String, String>? details;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const TransactionConfirmationDialog({
    super.key,
    required this.type,
    required this.amount,
    this.details,
    required this.onConfirm,
    this.onCancel,
  });

  /// Get transaction icon based on type
  IconData _getIcon() {
    switch (type) {
      case TransactionType.deposit:
        return Icons.add_circle;
      case TransactionType.sendMoney:
        return Icons.send;
      case TransactionType.bankTransfer:
        return Icons.account_balance;
      case TransactionType.collegePayment:
        return Icons.school;
      case TransactionType.mobileTopup:
        return Icons.phone_android;
      case TransactionType.billPayment:
        return Icons.receipt_long;
      case TransactionType.shopping:
        return Icons.shopping_cart;
    }
  }

  /// Get transaction color based on type
  Color _getColor() {
    switch (type) {
      case TransactionType.deposit:
        return Colors.green;
      case TransactionType.sendMoney:
        return Colors.teal;
      case TransactionType.bankTransfer:
        return Colors.blue;
      case TransactionType.collegePayment:
        return Colors.orange;
      case TransactionType.mobileTopup:
        return Colors.green;
      case TransactionType.billPayment:
        return Colors.red;
      case TransactionType.shopping:
        return Colors.purple;
    }
  }

  /// Get transaction title
  String _getTitle() {
    switch (type) {
      case TransactionType.deposit:
        return 'Confirm Deposit';
      case TransactionType.sendMoney:
        return 'Confirm Send Money';
      case TransactionType.bankTransfer:
        return 'Confirm Bank Transfer';
      case TransactionType.collegePayment:
        return 'Confirm College Payment';
      case TransactionType.mobileTopup:
        return 'Confirm Mobile Topup';
      case TransactionType.billPayment:
        return 'Confirm Bill Payment';
      case TransactionType.shopping:
        return 'Confirm Payment';
    }
  }

  /// Get confirmation message
  String _getMessage() {
    switch (type) {
      case TransactionType.deposit:
        return 'Are you sure you want to deposit this amount?';
      case TransactionType.sendMoney:
        return 'Are you sure you want to send this amount?';
      case TransactionType.bankTransfer:
        return 'Are you sure you want to transfer to this bank account?';
      case TransactionType.collegePayment:
        return 'Are you sure you want to pay college fees?';
      case TransactionType.mobileTopup:
        return 'Are you sure you want to recharge this number?';
      case TransactionType.billPayment:
        return 'Are you sure you want to pay this bill?';
      case TransactionType.shopping:
        return 'Are you sure you want to complete this payment?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              0.8, // Max 80% of screen height
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(), size: 48, color: color),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  _getMessage(),
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Amount Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Amount: ',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Additional Details
                if (details != null && details!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: details!.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Warning for non-deposit transactions
                if (type != TransactionType.deposit) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action cannot be undone',
                            style: TextStyle(
                              color: Colors.orange[300],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                          onCancel?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Confirm Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Static method to show the dialog
  static Future<bool?> show({
    required BuildContext context,
    required TransactionType type,
    required double amount,
    Map<String, String>? details,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TransactionConfirmationDialog(
        type: type,
        amount: amount,
        details: details,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }
}
