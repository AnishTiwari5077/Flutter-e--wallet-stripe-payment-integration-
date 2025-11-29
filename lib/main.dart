import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:app_wallet/providers/auth_provider.dart';
import 'package:app_wallet/providers/user_provider.dart';
import 'package:app_wallet/providers/payment_provider.dart';
import 'package:app_wallet/providers/transaction_provider.dart';
import 'package:app_wallet/services/payment_service.dart';
import 'package:app_wallet/screens/login_screen.dart';
import 'package:app_wallet/screens/register_screen.dart';
import 'package:app_wallet/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe with your publishable key
  PaymentService.initializeStripe(
    'pk_test_51SXvBHHKrFDpSpIkVxuXl5nyLySIPsmOBh6EOuy8Ih2xXqdFY3KdaSy0ga75PTjAEpG3wQtaGfKZFnyLr0WOwFD5002qz17NV2', // TODO: Replace with your actual key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider - Handles authentication
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // User Provider - Manages user state
        ChangeNotifierProvider(create: (_) => UserProvider()),

        // Payment Provider - Handles all payment operations
        ChangeNotifierProvider(create: (_) => PaymentProvider()),

        // Transaction Provider - Manages transaction history
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'E-Wallet App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF080814),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

// ============================================
// AUTH WRAPPER - Checks if user is logged in
// ============================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return FutureBuilder<bool>(
          future: authProvider.checkAuthStatus(),
          builder: (context, snapshot) {
            // Show loading screen while checking auth
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF080814),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              );
            }

            // If user is authenticated, go to dashboard
            if (authProvider.isAuthenticated && authProvider.user != null) {
              // Also sync with UserProvider
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<UserProvider>(
                  context,
                  listen: false,
                ).setUser(authProvider.user!);
              });
              return const DashboardScreen();
            }

            // Otherwise, show login screen
            return const LoginScreen();
          },
        );
      },
    );
  }
}
