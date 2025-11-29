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
  const MyApp({super.key});

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
            fillColor: Colors.white,
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
// AUTH WRAPPER (FIXED)
// ============================================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Kicks off the asynchronous check only ONCE in initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // We use read() here because we are only initiating the process;
      // we don't want the build method to be sensitive to the start of loading.
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // LISTEN to the AuthProvider for its state changes.
    final authProvider = context.watch<AuthProvider>();

    // 1. Show Loading Screen
    if (authProvider.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF080814),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Checking session...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // 2. User is Authenticated
    if (authProvider.isAuthenticated && authProvider.user != null) {
      // 💡 THE FIX: DEFER the cross-provider state change to the next frame.
      // This prevents the UserProvider's notifyListeners() from running
      // while AuthWrapper is still in the process of building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Safely update the UserProvider after the build cycle completes.
          context.read<UserProvider>().setUser(authProvider.user!);
        }
      });

      // Safely return the DashboardScreen.
      return const DashboardScreen();
    }

    // 3. User is NOT Authenticated
    return const LoginScreen();
  }
}
