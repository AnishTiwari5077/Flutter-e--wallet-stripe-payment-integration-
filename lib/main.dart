import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import 'package:app_wallet/core/network/api_client.dart';

// Data Sources
import 'package:app_wallet/data/datasources/auth_remote_data_source.dart';
import 'package:app_wallet/data/datasources/payment_remote_data_source.dart';
import 'package:app_wallet/data/datasources/transaction_remote_data_source.dart';

// Repositories
import 'package:app_wallet/data/repositories/auth_repository_impl.dart';
import 'package:app_wallet/data/repositories/payment_repository_impl.dart';
import 'package:app_wallet/data/repositories/transaction_repository_impl.dart';

// Use Cases
import 'package:app_wallet/domain/usecases/auth_usecases.dart';
import 'package:app_wallet/domain/usecases/payment_usecases.dart';
import 'package:app_wallet/domain/usecases/transaction_usecases.dart';

// ViewModels
import 'package:app_wallet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:app_wallet/presentation/viewmodels/payment_viewmodel.dart';
import 'package:app_wallet/presentation/viewmodels/transaction_viewmodel.dart';

// Services
import 'package:app_wallet/services/payment_service.dart';

// Views
import 'package:app_wallet/presentation/views/login_screen.dart';
import 'package:app_wallet/presentation/views/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PaymentService.initializeStripe(
    'pk_test_51SXvBHHKrFDpSpIkVxuXl5nyLySIPsmOBh6EOuy8Ih2xXqdFY3KdaSy0ga75PTjAEpG3wQtaGfKZFnyLr0WOwFD5002qz17NV2',
  );

  // --- Dependency Injection Setup ---
  final apiClient = ApiClient();

  // Data Sources
  final authRemoteDS = AuthRemoteDataSourceImpl(apiClient);
  final paymentRemoteDS = PaymentRemoteDataSourceImpl(apiClient);
  final transactionRemoteDS = TransactionRemoteDataSourceImpl(apiClient);

  // Repositories
  final authRepo = AuthRepositoryImpl(authRemoteDS);
  final paymentRepo = PaymentRepositoryImpl(paymentRemoteDS);
  final transactionRepo = TransactionRepositoryImpl(transactionRemoteDS);

  // Use Cases
  final loginUseCase = LoginUseCase(authRepo);
  final registerUseCase = RegisterUseCase(authRepo);
  final fetchUserUseCase = FetchUserUseCase(authRepo);

  final depositUseCase = DepositUseCase(paymentRepo);
  final sendMoneyUseCase = SendMoneyUseCase(paymentRepo);
  final bankTransferUseCase = BankTransferUseCase(paymentRepo);
  final collegePaymentUseCase = CollegePaymentUseCase(paymentRepo);
  final mobileTopupUseCase = MobileTopupUseCase(paymentRepo);
  final billPaymentUseCase = BillPaymentUseCase(paymentRepo);
  final shoppingPaymentUseCase = ShoppingPaymentUseCase(paymentRepo);

  final getAllTransactionsUseCase = GetAllTransactionsUseCase(transactionRepo);
  final getUserTransactionsUseCase = GetUserTransactionsUseCase(transactionRepo);

  runApp(MyApp(
    authProvider: AuthProvider(
      loginUseCase: loginUseCase,
      registerUseCase: registerUseCase,
      fetchUserUseCase: fetchUserUseCase,
    ),
    paymentProvider: PaymentProvider(
      depositUseCase: depositUseCase,
      sendMoneyUseCase: sendMoneyUseCase,
      bankTransferUseCase: bankTransferUseCase,
      collegePaymentUseCase: collegePaymentUseCase,
      mobileTopupUseCase: mobileTopupUseCase,
      billPaymentUseCase: billPaymentUseCase,
      shoppingPaymentUseCase: shoppingPaymentUseCase,
    ),
    transactionProvider: TransactionProvider(
      getAllTransactionsUseCase: getAllTransactionsUseCase,
      getUserTransactionsUseCase: getUserTransactionsUseCase,
    ),
  ));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final PaymentProvider paymentProvider;
  final TransactionProvider transactionProvider;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.paymentProvider,
    required this.transactionProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: paymentProvider),
        ChangeNotifierProvider.value(value: transactionProvider),
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
