import 'package:app_wallet/presentation/widgets/auth_transaction_helper.dart';
import 'package:app_wallet/presentation/widgets/complete_transaction_dialog.dart'
    show TransactionConfirmationDialog, TransactionType;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_wallet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:app_wallet/presentation/viewmodels/payment_viewmodel.dart';

// ✅ RECEIPT IMPORTS
import 'package:app_wallet/services/receipt_service.dart';
import 'package:app_wallet/presentation/views/receipt_screen.dart';


import 'package:uuid/uuid.dart';

class PaymentScreen extends StatefulWidget {
  final PaymentType paymentType;

  const PaymentScreen({super.key, required this.paymentType});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accountController = TextEditingController();
  final _nameController = TextEditingController();
  final _extraController = TextEditingController();
  
  // Custom Card Fields
  final _cardNumberController = TextEditingController();
  final _expMonthController = TextEditingController();
  final _expYearController = TextEditingController();
  final _cvcController = TextEditingController();

  // UI guard: prevents double-tap while a payment is being processed
  bool _isSubmitting = false;
  // Idempotency key generated ONCE before the confirmation dialog
  String? _pendingIdempotencyKey;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _accountController.dispose();
    _nameController.dispose();
    _extraController.dispose();
    _cardNumberController.dispose();
    _expMonthController.dispose();
    _expYearController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  TransactionType _getTransactionType() {
    switch (widget.paymentType) {
      case PaymentType.deposit:
        return TransactionType.deposit;
      case PaymentType.sendMoney:
        return TransactionType.sendMoney;
      case PaymentType.bankTransfer:
        return TransactionType.bankTransfer;
      case PaymentType.collegePayment:
        return TransactionType.collegePayment;
      case PaymentType.topup:
        return TransactionType.mobileTopup;
      case PaymentType.billPayment:
        return TransactionType.billPayment;
      case PaymentType.shopping:
        return TransactionType.shopping;
    }
  }

  Map<String, String> _buildTransactionDetails(double amount) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user!;

    switch (widget.paymentType) {
      case PaymentType.deposit:
        return {
          'Payment Method': 'Credit Card',
          'charge': '\$${(amount * 0.029).toStringAsFixed(2)}',
          'Total': '\$${(amount * 1.029).toStringAsFixed(2)}',
        };

      case PaymentType.sendMoney:
        return {
          'To': _phoneController.text.trim(),
          'Your Balance': '\$${user.balance.toStringAsFixed(2)}',
          'Balance After': '\$${(user.balance - amount).toStringAsFixed(2)}',
        };

      case PaymentType.bankTransfer:
        return {
          'Bank': _nameController.text.trim(),
          'Account': _accountController.text.trim(),
          'Your Balance': '\$${user.balance.toStringAsFixed(2)}',
        };

      case PaymentType.collegePayment:
        return {
          'Student ID': _accountController.text.trim(),
          'College': _nameController.text.trim(),
          'Semester': _extraController.text.trim(),
        };

      case PaymentType.topup:
        return {
          'Phone Number': _phoneController.text.trim(),
          'Operator': _nameController.text.trim(),
        };

      case PaymentType.billPayment:
        return {
          'Bill Type': _nameController.text.trim(),
          'Account': _accountController.text.trim(),
        };

      case PaymentType.shopping:
        return {'Merchant': _nameController.text.trim()};
    }
  }

  Future<void> _handlePayment() async {
    if (_isSubmitting) return; // local UI guard
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );
    final user = auth.user;

    if (user == null || user.id == null) {
      if (!mounted) return;
      _showMessage('Please login again', isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      _showMessage('Please enter a valid amount', isError: true);
      return;
    }

    if (widget.paymentType == PaymentType.sendMoney ||
        widget.paymentType == PaymentType.topup) {
      if (!paymentProvider.validatePhoneNumber(_phoneController.text.trim())) {
        if (!mounted) return;
        _showMessage(
          paymentProvider.errorMessage ?? 'Invalid phone',
          isError: true,
        );
        return;
      }
    }

    if (widget.paymentType != PaymentType.deposit) {
      if (user.balance < amount) {
        if (!mounted) return;
        _showMessage('Insufficient balance', isError: true);
        return;
      }
    }

    // ============================================
    // ✅ STEP 1: AUTHENTICATE UserEntity (BIOMETRIC/PIN)
    // ============================================
    if (!mounted) return;
    final authenticated = await TransactionAuthHelper.authenticate(context);

    if (!authenticated) {
      if (!mounted) return;
      _showMessage(
        'Authentication required to complete transaction',
        isError: true,
      );
      return;
    }

    // Generate idempotency key ONCE before showing the confirmation dialog
    _pendingIdempotencyKey = const Uuid().v4();

    // ============================================
    // ✅ STEP 2: SHOW CONFIRMATION DIALOG
    // ============================================
    if (!mounted) return;
    final confirmed = await TransactionConfirmationDialog.show(
      context: context,
      type: _getTransactionType(),
      amount: amount,
      details: _buildTransactionDetails(amount),
      onConfirm: () {},
      onCancel: () {},
    );

    if (confirmed != true) {
      if (!mounted) return;
      _pendingIdempotencyKey = null;
      _showMessage('Transaction cancelled', isError: false);
      return;
    }

    // Lock the UI — key was already generated before the dialog
    setState(() => _isSubmitting = true);
    final idempotencyKey = _pendingIdempotencyKey!;
    _pendingIdempotencyKey = null;

    // ✅ CAPTURE BALANCE BEFORE TRANSACTION
    final balanceBefore = user.balance;

    // ============================================
    // ✅ STEP 3: PROCESS PAYMENT
    // ============================================
    bool success = false;
    dynamic result;

    switch (widget.paymentType) {
      case PaymentType.deposit:
        result = await paymentProvider.depositMoney(
          userId: user.id!,
          amount: amount,
          cardNumber: _cardNumberController.text.trim(),
          expMonth: _expMonthController.text.trim(),
          expYear: _expYearController.text.trim(),
          cvc: _cvcController.text.trim(),
          idempotencyKey: idempotencyKey,
        );
        success = result['success'] == true;

        if (success && result['user'] != null) {
          auth.updateUser(result['user']);
        }
        break;

      case PaymentType.sendMoney:
        success = await paymentProvider.sendMoney(
          senderId: user.id!,
          receiverPhone: _phoneController.text.trim(),
          amount: amount,
          idempotencyKey: idempotencyKey,
        );
        if (success) {
          // Server is source of truth — just refresh, no local deduction
          await auth.refreshUser();
        }
        break;

      case PaymentType.bankTransfer:
        success = await paymentProvider.bankTransfer(
          userId: user.id!,
          accountNumber: _accountController.text.trim(),
          bankName: _nameController.text.trim(),
          amount: amount,
          idempotencyKey: idempotencyKey,
        );
        if (success) {
          await auth.refreshUser();
        }
        break;

      case PaymentType.collegePayment:
        success = await paymentProvider.collegePayment(
          userId: user.id!,
          studentId: _accountController.text.trim(),
          collegeName: _nameController.text.trim(),
          amount: amount,
          semester: _extraController.text.trim(),
          idempotencyKey: idempotencyKey,
        );
        if (success) {
          await auth.refreshUser();
        }
        break;

      case PaymentType.topup:
        success = await paymentProvider.mobileTopup(
          userId: user.id!,
          phoneNumber: _phoneController.text.trim(),
          operator: _nameController.text.trim(),
          amount: amount,
          idempotencyKey: idempotencyKey,
        );
        if (success) {
          await auth.refreshUser();
        }
        break;

      case PaymentType.billPayment:
        success = await paymentProvider.billPayment(
          userId: user.id!,
          billType: _nameController.text.trim(),
          accountNumber: _accountController.text.trim(),
          amount: amount,
          idempotencyKey: idempotencyKey,
        );
        if (success) {
          await auth.refreshUser();
        }
        break;

      case PaymentType.shopping:
        success = await paymentProvider.shoppingPayment(
          userId: user.id!,
          merchantName: _nameController.text.trim(),
          amount: amount,
          idempotencyKey: idempotencyKey,
          items: [],
        );
        if (success) {
          await auth.refreshUser();
        }
        break;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      final message = widget.paymentType == PaymentType.deposit
          ? result['message']
          : paymentProvider.successMessage;

      _showMessage(message ?? 'Success!', isError: false);

      // ✅ ========================================
      // ✅ GENERATE AND SHOW RECEIPT
      // ✅ Skip receipt for deposit to avoid potential overflow
      // ✅ Users can still see receipt from transaction history
      // ✅ ========================================
      if (widget.paymentType != PaymentType.deposit) {
        await _showTransactionModel(
          amount: amount,
          balanceBefore: balanceBefore,
          balanceAfter: auth.user?.balance ?? balanceBefore,
        );
      }

      // Navigate back to dashboard
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      final message = widget.paymentType == PaymentType.deposit
          ? result['message']
          : paymentProvider.errorMessage;

      _showMessage(message ?? 'Failed', isError: true);
    }
  }

  // ✅ ========================================
  // ✅ NEW METHOD: SHOW TRANSACTION RECEIPT
  // ✅ ========================================
  Future<void> _showTransactionModel({
    required double amount,
    required double balanceBefore,
    required double balanceAfter,
  }) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user!;

      // Create transaction data map
      final transactionData = <String, dynamic>{
        'transaction_id': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        'type': widget.paymentType.name,
        'amount': amount,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'Completed',
      };

      // Add specific fields based on payment type
      switch (widget.paymentType) {
        case PaymentType.deposit:
          transactionData['processing_fee'] = amount * 0.029;
          transactionData['total_amount'] = amount * 1.029;
          break;

        case PaymentType.sendMoney:
          transactionData['receiver_phone'] = _phoneController.text.trim();
          break;

        case PaymentType.bankTransfer:
          transactionData['bank_name'] = _nameController.text.trim();
          transactionData['account_number'] = _accountController.text.trim();
          break;

        case PaymentType.collegePayment:
          transactionData['college_name'] = _nameController.text.trim();
          transactionData['student_id'] = _accountController.text.trim();
          transactionData['semester'] = _extraController.text.trim();
          break;

        case PaymentType.topup:
          transactionData['phone_number'] = _phoneController.text.trim();
          transactionData['operator'] = _nameController.text.trim();
          break;

        case PaymentType.billPayment:
          transactionData['bill_type'] = _nameController.text.trim();
          transactionData['account_number'] = _accountController.text.trim();
          break;

        case PaymentType.shopping:
          transactionData['merchant_name'] = _nameController.text.trim();
          break;
      }

      // Create receipt model
      final receipt = ReceiptService.createReceiptFromTransaction(
        transactionData,
        user.name,
        user.email,
        user.phone,
        balanceBefore,
        balanceAfter,
      );

      // Show receipt screen
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReceiptScreen(receipt: receipt)),
      );
    } catch (e) {
      // If receipt generation fails, don't block the UserEntity
      debugPrint('Error generating receipt: $e');

      // Optionally show a message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Transaction successful but receipt generation failed',
          ),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          paymentProvider.getPaymentTypeName(widget.paymentType),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: paymentProvider
                      .getPaymentTypeColor(widget.paymentType)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: paymentProvider
                        .getPaymentTypeColor(widget.paymentType)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      paymentProvider.getPaymentTypeIcon(widget.paymentType),
                      size: 60,
                      color: paymentProvider.getPaymentTypeColor(
                        widget.paymentType,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      paymentProvider.getPaymentTypeName(widget.paymentType),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (auth.user != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Balance: \$${auth.user!.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              ..._buildFormFields(),

              const SizedBox(height: 30),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  // Disabled if the ViewModel is loading OR the UI is submitting
                  onPressed: (paymentProvider.isLoading || _isSubmitting)
                      ? null
                      : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paymentProvider.getPaymentTypeColor(
                      widget.paymentType,
                    ),
                    disabledBackgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: paymentProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.paymentType == PaymentType.deposit
                              ? 'Proceed to Payment'
                              : 'Confirm Payment',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    final fields = <Widget>[];

    switch (widget.paymentType) {
      case PaymentType.deposit:
        fields.addAll([
          _buildTextField(
            controller: _amountController,
            label: 'Amount (USD)',
            hint: 'Enter amount',
            prefix: '\$ ',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Text(
            'Card Details',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _cardNumberController,
            label: 'Card Number',
            hint: '1234 5678 9101 1121',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _expMonthController,
                  label: 'MM',
                  hint: '12',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _expYearController,
                  label: 'YY or YYYY',
                  hint: '2025',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _cvcController,
                  label: 'CVC',
                  hint: '123',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ]);
        break;

      case PaymentType.sendMoney:
        fields.addAll([
          _buildTextField(
            controller: _phoneController,
            label: 'Receiver Phone Number',
            hint: 'Enter phone number',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _amountController,
            label: 'Amount (USD)',
            hint: 'Enter amount',
            prefix: '\$ ',
            keyboardType: TextInputType.number,
          ),
        ]);
        break;

      case PaymentType.bankTransfer:
        fields.addAll([
          _buildTextField(
            controller: _nameController,
            label: 'Bank Name',
            hint: 'Enter bank name',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _accountController,
            label: 'Account Number',
            hint: 'Enter account number',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _amountController,
            label: 'Amount (USD)',
            hint: 'Enter amount',
            prefix: '\$ ',
            keyboardType: TextInputType.number,
          ),
        ]);
        break;

      case PaymentType.collegePayment:
        fields.addAll([
          _buildTextField(
            controller: _nameController,
            label: 'College Name',
            hint: 'Enter college name',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _accountController,
            label: 'Student ID',
            hint: 'Enter student ID',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _extraController,
            label: 'Semester',
            hint: 'e.g., Fall 2024',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _amountController,
            label: 'Amount (USD)',
            hint: 'Enter amount',
            prefix: '\$ ',
            keyboardType: TextInputType.number,
          ),
        ]);
        break;

      case PaymentType.topup:
        fields.addAll([
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter phone number',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Operator',
            hint: 'e.g., Verizon, AT&T',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _amountController,
            label: 'Amount (USD)',
            hint: 'Enter amount',
            prefix: '\$ ',
            keyboardType: TextInputType.number,
          ),
        ]);
        break;

      case PaymentType.billPayment:
        fields.addAll([
          _buildTextField(
            controller: _nameController,
            label: 'Bill Type',
            hint: 'e.g., Electricity, Water',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _accountController,
            label: 'Account Number',
            hint: 'Enter account number',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _amountController,
            label: 'Amount (USD)',
            hint: 'Enter amount',
            prefix: '\$ ',
            keyboardType: TextInputType.number,
          ),
        ]);
        break;

      case PaymentType.shopping:
        fields.addAll([
          _buildTextField(
            controller: _nameController,
            label: 'Merchant Name',
            hint: 'Enter merchant name',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _amountController,
            label: 'Amount (USD)',
            hint: 'Enter amount',
            prefix: '\$ ',
            keyboardType: TextInputType.number,
          ),
        ]);
        break;
    }

    return fields;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefix,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: (value) {
        if (label == 'Card Number') {
          final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
          if (digits.length < 13 || digits.length > 19) {
            return 'Enter a valid card number (13-19 digits)';
          }
          return null;
        }
        if (label == 'CVC') {
          final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
          if (digits.length < 3 || digits.length > 4) {
            return 'Enter a valid CVC (3-4 digits)';
          }
          return null;
        }
        if (label == 'MM') {
          final month = int.tryParse(value ?? '');
          if (month == null || month < 1 || month > 12) {
            return 'Enter a valid month (1-12)';
          }
          return null;
        }
        if (label == 'YY or YYYY') {
          final year = int.tryParse(value ?? '');
          final currentYear = DateTime.now().year;
          if (year == null || (year < currentYear % 100 && year > 0 && year < 100) || (year >= 100 && year < currentYear)) {
            return 'Enter a valid expiry year';
          }
          return null;
        }
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
