import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_wallet/providers/auth_provider.dart';
import 'package:app_wallet/providers/payment_provider.dart';
import 'package:app_wallet/providers/transaction_provider.dart';
import 'package:app_wallet/services/payment_service.dart';
import 'package:app_wallet/screens/login_screen.dart';
import 'package:app_wallet/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PaymentService.initializeStripe(
    'pk_test_51SXvBHHKrFDpSpIkVxuXl5nyLySIPsmOBh6EOuy8Ih2xXqdFY3KdaSy0ga75PTjAEpG3wQtaGfKZFnyLr0WOwFD5002qz17NV2',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'E-Wallet App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final isAuthenticated = await auth.checkAuthStatus();

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.purpleAccent,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.purpleAccent),
            const SizedBox(height: 16),
            const Text('Loading...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
