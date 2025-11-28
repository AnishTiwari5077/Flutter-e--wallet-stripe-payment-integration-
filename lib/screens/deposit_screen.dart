import 'package:app_wallet/widgets/round_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/payment_service.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});
  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final amountController = TextEditingController();
  bool loading = false;

  void _deposit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = auth.user?.email ?? '';
    final input = double.tryParse(amountController.text.trim());
    if (input == null || input <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final cents = (input * 100).toInt();

    setState(() => loading = true);
    final ok = await PaymentService.payWithPaymentSheet(
      amountInCents: cents,
      userEmail: email,
    );
    setState(() => loading = false);

    if (ok) {
      await auth.refreshUser();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deposit successful')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deposit failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      appBar: AppBar(title: const Text('Deposit')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RoundedTextField(
              controller: amountController,
              hint: 'Amount in USD (e.g. 10.00)',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _deposit,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }
}
