import 'package:app_wallet/widgets/round_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final phone = TextEditingController();
  final avatar = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B15),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Register',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              RoundedTextField(controller: name, hint: 'Full name'),
              const SizedBox(height: 10),
              RoundedTextField(controller: email, hint: 'Email'),
              const SizedBox(height: 10),
              RoundedTextField(
                controller: pass,
                hint: 'Password',
                obscure: true,
              ),
              const SizedBox(height: 10),
              RoundedTextField(controller: phone, hint: 'Phone'),
              const SizedBox(height: 10),
              RoundedTextField(
                controller: avatar,
                hint: 'Avatar URL (optional)',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: auth.loading
                    ? null
                    : () async {
                        final ok = await auth.register(
                          name.text.trim(),
                          email.text.trim(),
                          pass.text.trim(),
                          phone: phone.text.trim(),
                          avatar: avatar.text.trim(),
                        );
                        if (ok) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registration failed'),
                            ),
                          );
                        }
                      },
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
