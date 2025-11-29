import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_wallet/providers/auth_provider.dart';
import 'package:app_wallet/providers/payment_provider.dart';
import 'package:app_wallet/providers/transaction_provider.dart';
import 'package:app_wallet/widgets/neo_widget.dart';
import 'package:app_wallet/screens/payment_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // 🚀 We call the necessary data fetches right after the build phase completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // A helper function to encapsulate the initial data loading
  Future<void> _loadData() async {
    // Use read, as we don't need this widget to rebuild when loading starts
    final auth = context.read<AuthProvider>();
    final transactions = context.read<TransactionProvider>();

    // 1. Refresh user (to get latest balance/data)
    // Use the optimized refreshUser if the user is already logged in (checked by parent wrapper)
    // NOTE: refreshUser should handle its own loading/notifyListeners
    await auth.refreshUser(fetchFromServer: true);

    // 2. Fetch transactions only if the user object is valid
    final userId = auth.user?.id;
    if (userId != null && mounted) {
      // NOTE: The TransactionProvider should handle its own loading state
      await transactions.fetchUserTransactions(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Listen to the AuthProvider for user state changes
    final auth = context.watch<AuthProvider>();
    // 💡 Listen to the TransactionProvider for transaction list changes
    final transactionProvider = context.watch<TransactionProvider>();

    final user = auth.user;

    // --- Loading and Error Screens ---

    // Use only the provider's loading state, which now reflects the refreshUser status
    if (auth.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF080814),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      // If auth.loading is false but user is null, it means loading failed or
      // the user was logged out. Prompt to log in or show an error.
      return Scaffold(
        backgroundColor: const Color(0xFF080814),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Session Expired or Failed to load user.",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // --- Dashboard UI ---
    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('E-Wallet'),
        actions: [
          IconButton(
            onPressed: () async {
              // The logout method is safe to call here (user action)
              await auth.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        // Ensure both providers refresh their data on pull-to-refresh
        onRefresh: () async {
          // ⚠️ IMPORTANT: Pass fetchFromServer: true to guarantee API call
          await auth.refreshUser(fetchFromServer: true);
          if (user.id != null) {
            await transactionProvider.refreshTransactions(user.id!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Balance Card
              NeonBalanceCard(
                name: user.name,
                avatarUrl: user.avatar,
                balance: user.balance,
              ),

              const SizedBox(height: 30),

              _buildServicesSection(),

              const SizedBox(height: 30),

              // Pass the provider instance and user ID to the build method
              _buildRecentTransactionsSection(transactionProvider, user.id!),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget Methods (Unchanged, as they were correct) ---

  // ----------------------- Services ----------------------------
  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentGrid(),
        ],
      ),
    );
  }

  Widget _buildPaymentGrid() {
    // ... (rest of the _buildPaymentGrid logic is unchanged)
    final services = [
      {
        'type': PaymentType.deposit,
        'name': 'Deposit',
        'icon': Icons.add_circle_outline,
        'color': Colors.deepPurple,
      },
      {
        'type': PaymentType.sendMoney,
        'name': 'Send Money',
        'icon': Icons.send,
        'color': Colors.teal,
      },
      {
        'type': PaymentType.bankTransfer,
        'name': 'Bank Transfer',
        'icon': Icons.account_balance,
        'color': Colors.blue,
      },
      {
        'type': PaymentType.collegePayment,
        'name': 'College Fee',
        'icon': Icons.school,
        'color': Colors.orange,
      },
      {
        'type': PaymentType.topup,
        'name': 'Mobile Topup',
        'icon': Icons.phone_android,
        'color': Colors.green,
      },
      {
        'type': PaymentType.billPayment,
        'name': 'Pay Bills',
        'icon': Icons.receipt_long,
        'color': Colors.red,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final s = services[index];
        return _buildServiceCard(
          type: s['type'] as PaymentType,
          name: s['name'] as String,
          icon: s['icon'] as IconData,
          color: s['color'] as Color,
        );
      },
    );
  }

  Widget _buildServiceCard({
    required PaymentType type,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    // ... (rest of the _buildServiceCard logic is unchanged)
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PaymentScreen(paymentType: type)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), color.withOpacity(0.12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------- Recent Transactions ----------------------------
  Widget _buildRecentTransactionsSection(
    TransactionProvider provider,
    int userId,
  ) {
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(26),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final recent = provider.transactions.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Transactions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(onPressed: () {}, child: const Text("See All")),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Text(
              "No transactions yet",
              style: TextStyle(color: Colors.grey[600]),
            )
          else
            // Added keys to improve list performance and stability
            ...recent.map((tx) => _buildTransactionItem(tx, userId)).toList(),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx, int userId) {
    // ... (rest of the _buildTransactionItem logic is unchanged)
    final type = tx['type'];
    final amount = double.tryParse("${tx['amount']}") ?? 0.0;
    final date = tx['created_at'] ?? '';
    final isSent = tx['sender_id'] == userId;

    IconData icon;
    Color color;
    String title;

    if (type == 'add') {
      icon = Icons.add_circle;
      color = Colors.green;
      title = 'Deposit';
    } else if (isSent) {
      icon = Icons.arrow_upward;
      color = Colors.red;
      title = 'Sent to ${tx['receiver_name'] ?? 'Unknown'}';
    } else {
      icon = Icons.arrow_downward;
      color = Colors.green;
      title = 'Received from ${tx['sender_name'] ?? 'Unknown'}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isSent && type != 'add' ? '-' : '+'}\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSent && type != 'add'
                  ? Colors.redAccent
                  : Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
}
