import 'package:app_wallet/services/api_services.dart';
import 'package:app_wallet/widgets/round_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});
  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final phone = TextEditingController();
  final amount = TextEditingController();

  bool loading = false;

  void _send() async {
    setState(() => loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final senderId = auth.user?.id ?? 0;
    final amountCents = (double.tryParse(amount.text.trim()) ?? 0) * 100;

    final ok = await ApiService.sendMoney(
      senderId,
      phone.text.trim(),
      amountCents.toInt(),
    );
    setState(() => loading = false);

    if (ok) {
      await auth.refreshUser();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sent successfully')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Send failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      appBar: AppBar(title: const Text('Send Money')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RoundedTextField(controller: phone, hint: 'Receiver phone'),
            const SizedBox(height: 12),
            RoundedTextField(controller: amount, hint: 'Amount (e.g. 5.50)'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _send,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
