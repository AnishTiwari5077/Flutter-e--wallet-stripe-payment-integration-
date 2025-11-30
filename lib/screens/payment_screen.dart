import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_wallet/providers/auth_provider.dart';
import 'package:app_wallet/providers/payment_provider.dart';

class PaymentScreen extends StatefulWidget {
  final PaymentType paymentType;

  const PaymentScreen({Key? key, required this.paymentType}) : super(key: key);

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

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _accountController.dispose();
    _nameController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );
    final user = auth.user;

    if (user == null || user.id == null) {
      _showMessage('Please login again', isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount', isError: true);
      return;
    }

    bool success = false;
    dynamic result;

    switch (widget.paymentType) {
      case PaymentType.deposit:
        // Deposit returns Map with user object
        result = await paymentProvider.depositMoney(
          userId: user.id!,
          amount: amount,
        );
        success = result['success'] == true;

        // Update user with fresh data from backend
        if (success && result['user'] != null) {
          auth.updateUser(result['user']);
        }
        break;

      case PaymentType.sendMoney:
        if (!paymentProvider.validatePhoneNumber(
          _phoneController.text.trim(),
        )) {
          _showMessage(
            paymentProvider.errorMessage ?? 'Invalid phone',
            isError: true,
          );
          return;
        }
        if (user.balance < amount) {
          _showMessage('Insufficient balance', isError: true);
          return;
        }
        success = await paymentProvider.sendMoney(
          senderId: user.id!,
          receiverPhone: _phoneController.text.trim(),
          amount: amount,
        );
        // Deduct money immediately for instant UI feedback
        if (success) {
          auth.deductMoney(amount);
          // Then refresh from backend to ensure accuracy
          await auth.refreshUser();
        }
        break;

      case PaymentType.bankTransfer:
        if (user.balance < amount) {
          _showMessage('Insufficient balance', isError: true);
          return;
        }
        success = await paymentProvider.bankTransfer(
          userId: user.id!,
          accountNumber: _accountController.text.trim(),
          bankName: _nameController.text.trim(),
          amount: amount,
        );
        if (success) {
          auth.deductMoney(amount);
          await auth.refreshUser();
        }
        break;

      case PaymentType.collegePayment:
        if (user.balance < amount) {
          _showMessage('Insufficient balance', isError: true);
          return;
        }
        success = await paymentProvider.collegePayment(
          userId: user.id!,
          studentId: _accountController.text.trim(),
          collegeName: _nameController.text.trim(),
          amount: amount,
          semester: _extraController.text.trim(),
        );
        if (success) {
          auth.deductMoney(amount);
          await auth.refreshUser();
        }
        break;

      case PaymentType.topup:
        if (user.balance < amount) {
          _showMessage('Insufficient balance', isError: true);
          return;
        }
        success = await paymentProvider.mobileTopup(
          userId: user.id!,
          phoneNumber: _phoneController.text.trim(),
          operator: _nameController.text.trim(),
          amount: amount,
        );
        if (success) {
          auth.deductMoney(amount);
          await auth.refreshUser();
        }
        break;

      case PaymentType.billPayment:
        if (user.balance < amount) {
          _showMessage('Insufficient balance', isError: true);
          return;
        }
        success = await paymentProvider.billPayment(
          userId: user.id!,
          billType: _nameController.text.trim(),
          accountNumber: _accountController.text.trim(),
          amount: amount,
        );
        if (success) {
          auth.deductMoney(amount);
          await auth.refreshUser();
        }
        break;

      case PaymentType.shopping:
        if (user.balance < amount) {
          _showMessage('Insufficient balance', isError: true);
          return;
        }
        success = await paymentProvider.shoppingPayment(
          userId: user.id!,
          merchantName: _nameController.text.trim(),
          amount: amount,
          items: [],
        );
        if (success) {
          auth.deductMoney(amount);
          await auth.refreshUser();
        }
        break;
    }

    if (mounted) {
      if (success) {
        // Get message from result or provider
        final message = widget.paymentType == PaymentType.deposit
            ? result['message']
            : paymentProvider.successMessage;

        _showMessage(message ?? 'Success!', isError: false);

        // Return true to signal success to dashboard
        Navigator.pop(context, true);
      } else {
        // Get error message from result or provider
        final message = widget.paymentType == PaymentType.deposit
            ? result['message']
            : paymentProvider.errorMessage;

        _showMessage(message ?? 'Failed', isError: true);
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
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

              // Icon and Title Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: paymentProvider
                      .getPaymentTypeColor(widget.paymentType)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: paymentProvider
                        .getPaymentTypeColor(widget.paymentType)
                        .withOpacity(0.3),
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
                          color: Colors.black.withOpacity(0.3),
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

              // Dynamic Fields Based on Payment Type
              ..._buildFormFields(),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: paymentProvider.isLoading ? null : _handlePayment,
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

              // Info Text
              const SizedBox(height: 20),
              if (widget.paymentType == PaymentType.deposit)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You will be redirected to Stripe payment page',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
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
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
