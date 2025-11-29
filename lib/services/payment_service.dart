import 'dart:convert';

import 'package:app_wallet/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  // Initialize Stripe - call this in main.dart before runApp()
  static void initializeStripe(String publishableKey) {
    Stripe.publishableKey = publishableKey;
  }

  // ============================================
  // PAY WITH STRIPE PAYMENT SHEET
  // ============================================
  // IMPORTANT: Amount should be in DOLLARS, not cents
  // Backend will convert to cents automatically
  static Future<Map<String, dynamic>> payWithPaymentSheet({
    required double amount, // Amount in dollars (e.g., 100.0 for $100)
    required int userId, // User ID instead of email
  }) async {
    try {
      // Validate amount
      if (amount <= 0) {
        return {'success': false, 'message': 'Amount must be greater than 0'};
      }

      print('Starting payment for \$$amount');

      // 1. Create payment intent on backend
      final resp = await http.post(
        Uri.parse('${ApiService.baseUrl}/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}), // Send amount in dollars
      );

      print('Payment Intent Response: ${resp.statusCode}');
      print('Payment Intent Body: ${resp.body}');

      if (resp.statusCode != 200) {
        final body = jsonDecode(resp.body);
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to create payment intent',
        };
      }

      final body = jsonDecode(resp.body);
      final clientSecret = body['clientSecret'];

      if (clientSecret == null) {
        return {'success': false, 'message': 'Invalid payment intent response'};
      }

      // 2. Initialize PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'E-Wallet App',
          style: ThemeMode.system,
        ),
      );

      print('Payment sheet initialized');

      // 3. Present Payment Sheet to user
      await Stripe.instance.presentPaymentSheet();

      print('Payment completed successfully');

      // 4. Update balance in backend after successful payment
      final updateResult = await ApiService.updateBalance(userId, amount);

      if (updateResult['success'] == true) {
        return {
          'success': true,
          'message': 'Payment successful! Balance updated.',
          'user': updateResult['user'],
        };
      } else {
        return {
          'success': false,
          'message': updateResult['message'] ?? 'Failed to update balance',
        };
      }
    } on StripeException catch (e) {
      print('Stripe Error: ${e.error.message}');

      // Handle different Stripe error codes
      String errorMessage = 'Payment failed';

      if (e.error.code == FailureCode.Canceled) {
        errorMessage = 'Payment cancelled by user';
      } else if (e.error.code == FailureCode.Failed) {
        errorMessage = 'Payment failed. Please try again.';
      } else if (e.error.code == FailureCode.Timeout) {
        errorMessage = 'Payment timeout. Please try again.';
      } else {
        errorMessage = e.error.localizedMessage ?? 'Payment failed';
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('Payment Error: $e');
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // ============================================
  // SEND MONEY TO ANOTHER USER
  // ============================================
  static Future<Map<String, dynamic>> sendMoney({
    required int senderId,
    required String receiverPhone,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        return {'success': false, 'message': 'Amount must be greater than 0'};
      }

      print('Sending \$$amount from user $senderId to phone $receiverPhone');

      final result = await ApiService.sendMoney(
        senderId,
        receiverPhone,
        amount,
      );

      return result;
    } catch (e) {
      print('Send Money Error: $e');
      return {'success': false, 'message': 'Failed to send money: $e'};
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  // Validate amount string
  static bool validateAmount(String amountText) {
    if (amountText.isEmpty) return false;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return false;

    return true;
  }

  // Format currency
  static String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Parse amount from string
  static double? parseAmount(String amountText) {
    try {
      return double.parse(amountText);
    } catch (e) {
      return null;
    }
  }

  // Convert dollars to cents (if needed for display)
  static int dollarsToCents(double dollars) {
    return (dollars * 100).round();
  }

  // Convert cents to dollars (if needed for display)
  static double centsToDollars(int cents) {
    return cents / 100.0;
  }
}

// ============================================
// EXAMPLE USAGE IN SCREENS
// ============================================
/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_wallet/services/payment_service.dart';
import 'package:app_wallet/providers/user_provider.dart';

class AddMoneyScreen extends StatefulWidget {
  @override
  _AddMoneyScreenState createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleAddMoney() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found'), backgroundColor: Colors.red),
      );
      return;
    }

    final amount = PaymentService.parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await PaymentService.payWithPaymentSheet(
      amount: amount,
      userId: user!.id!,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Update user in provider
      if (result['user'] != null) {
        userProvider.updateUser(result['user']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Money')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (USD)',
                prefixText: '\$ ',
              ),
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleAddMoney,
                    child: Text('Add Money'),
                  ),
          ],
        ),
      ),
    );
  }
}

// Send Money Example
class SendMoneyScreen extends StatefulWidget {
  @override
  _SendMoneyScreenState createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSendMoney() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found'), backgroundColor: Colors.red),
      );
      return;
    }

    final amount = PaymentService.parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await PaymentService.sendMoney(
      senderId: user!.id!,
      receiverPhone: _phoneController.text.trim(),
      amount: amount,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Deduct money from user balance
      userProvider.deductMoney(amount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send Money')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Receiver Phone Number',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (USD)',
                prefixText: '\$ ',
              ),
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleSendMoney,
                    child: Text('Send Money'),
                  ),
          ],
        ),
      ),
    );
  }
}
*/
