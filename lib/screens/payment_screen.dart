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

    switch (widget.paymentType) {
      case PaymentType.deposit:
        success = await paymentProvider.depositMoney(
          userId: user.id!,
          amount: amount,
        );
        if (success) await auth.refreshUser();
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
        if (success) auth.deductMoney(amount);
        break;

      case PaymentType.bankTransfer:
        success = await paymentProvider.bankTransfer(
          userId: user.id!,
          accountNumber: _accountController.text.trim(),
          bankName: _nameController.text.trim(),
          amount: amount,
        );
        if (success) auth.deductMoney(amount);
        break;

      case PaymentType.collegePayment:
        success = await paymentProvider.collegePayment(
          userId: user.id!,
          studentId: _accountController.text.trim(),
          collegeName: _nameController.text.trim(),
          amount: amount,
          semester: _extraController.text.trim(),
        );
        if (success) auth.deductMoney(amount);
        break;

      case PaymentType.topup:
        success = await paymentProvider.mobileTopup(
          userId: user.id!,
          phoneNumber: _phoneController.text.trim(),
          operator: _nameController.text.trim(),
          amount: amount,
        );
        if (success) auth.deductMoney(amount);
        break;

      case PaymentType.billPayment:
        success = await paymentProvider.billPayment(
          userId: user.id!,
          billType: _nameController.text.trim(),
          accountNumber: _accountController.text.trim(),
          amount: amount,
        );
        if (success) auth.deductMoney(amount);
        break;

      case PaymentType.shopping:
        success = await paymentProvider.shoppingPayment(
          userId: user.id!,
          merchantName: _nameController.text.trim(),
          amount: amount,
          items: [],
        );
        if (success) auth.deductMoney(amount);
        break;
    }

    if (mounted) {
      if (success) {
        _showMessage(
          paymentProvider.successMessage ?? 'Success!',
          isError: false,
        );
        Navigator.pop(context);
      } else {
        _showMessage(paymentProvider.errorMessage ?? 'Failed', isError: true);
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
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
        title: Text(paymentProvider.getPaymentTypeName(widget.paymentType)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Icon and Title
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
                    if (auth.user != null)
                      Text(
                        'Balance: \$${auth.user!.balance.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
                height: 50,
                child: ElevatedButton(
                  onPressed: paymentProvider.isLoading ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paymentProvider.getPaymentTypeColor(
                      widget.paymentType,
                    ),
                    disabledBackgroundColor: Colors.grey[800],
                  ),
                  child: paymentProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.paymentType == PaymentType.deposit
                              ? 'Proceed to Payment'
                              : 'Confirm Payment',
                          style: const TextStyle(fontSize: 16),
                        ),
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
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
