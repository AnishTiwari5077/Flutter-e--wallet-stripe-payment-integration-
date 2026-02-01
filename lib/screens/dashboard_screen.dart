import 'package:app_wallet/screens/security_setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_wallet/providers/auth_provider.dart';
import 'package:app_wallet/providers/payment_provider.dart';
import 'package:app_wallet/providers/transaction_provider.dart';
import 'package:app_wallet/widgets/neo_widget.dart';
import 'package:app_wallet/screens/payment_screen.dart';
import 'package:app_wallet/screens/transaction_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoggingOut = false; // NEW: Track logout state

  @override
  void initState() {
    super.initState();
    // Fetch latest data after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final transactions = context.read<TransactionProvider>();

    // Refresh user data from server
    await auth.refreshUser();

    // Fetch transactions if user exists
    if (!mounted) return;
    if (auth.user?.id != null) {
      await transactions.fetchUserTransactions(auth.user!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final user = auth.user;

    // Show loading during logout to prevent session expired flash
    if (_isLoggingOut) {
      return const Scaffold(
        backgroundColor: Color(0xFF080814),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.purpleAccent),
              SizedBox(height: 16),
              Text(
                'Logging out...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Loading State
    if (auth.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF080814),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // No User State - But only show if NOT logging out
    if (user == null && !_isLoggingOut) {
      // Automatically navigate to login instead of showing error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });

      // Show minimal loading screen while navigating
      return const Scaffold(
        backgroundColor: Color(0xFF080814),
        body: Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
      );
    }

    // Main Dashboard UI
    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'E-Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Security Icon - NEW
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SecuritySettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.security, color: Colors.white),
            tooltip: 'Security Settings',
          ),
          // History Icon
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Transaction History',
          ),
          // Logout Icon - IMPROVED
          IconButton(
            onPressed: () async {
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;
              if (!mounted) return;

              // Set logout state to prevent error screen
              setState(() {
                _isLoggingOut = true;
              });

              // Clear auth state
              await auth.logout();

              // Navigate immediately
              if (!mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await auth.refreshUser();
                if (!mounted) return;
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

                    // Services Section
                    _buildServicesSection(),

                    const SizedBox(height: 30),

                    // Recent Transactions Section
                    _buildRecentTransactionsSection(
                      transactionProvider,
                      user.id!,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================
  // SERVICES SECTION
  // ============================================
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        // Navigate to payment screen and wait for result
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PaymentScreen(paymentType: type)),
        );

        // If payment was successful, refresh data
        if (result == true && mounted) {
          final auth = context.read<AuthProvider>();
          final transactions = context.read<TransactionProvider>();

          // Refresh user balance
          await auth.refreshUser();

          // Refresh transactions
          if (!mounted) return;
          if (auth.user?.id != null) {
            await transactions.refreshTransactions(auth.user!.id!);
          }

          // Show success feedback
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: .3), color.withValues(alpha: .12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
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

  // ============================================
  // RECENT TRANSACTIONS SECTION
  // ============================================
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
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransactionHistoryScreen(),
                    ),
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.purpleAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 60, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by adding money to your wallet',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ...recent.map((tx) => _buildTransactionItem(tx, userId)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx, int userId) {
    final type = tx['type'] ?? '';
    final amount = double.tryParse('${tx['amount']}') ?? 0.0;
    final date = tx['created_at'] ?? '';
    final isSent = tx['sender_id'] == userId;

    IconData icon;
    Color color;
    String title;

    // Handle all transaction types properly
    switch (type) {
      case 'add':
        icon = Icons.add_circle;
        color = Colors.green;
        title = 'Deposit';
        break;

      case 'send':
        if (isSent) {
          icon = Icons.arrow_upward;
          color = Colors.red;
          final receiverName = tx['receiver_name']?.toString();
          title = receiverName != null && receiverName.isNotEmpty
              ? 'Sent to $receiverName'
              : 'Sent Money';
        } else {
          icon = Icons.arrow_downward;
          color = Colors.green;
          final senderName = tx['sender_name']?.toString();
          title = senderName != null && senderName.isNotEmpty
              ? 'Received from $senderName'
              : 'Received Money';
        }
        break;

      case 'bank_transfer':
        icon = Icons.account_balance;
        color = Colors.blue;
        title = 'Bank Transfer';
        break;

      case 'college_payment':
        icon = Icons.school;
        color = Colors.orange;
        title = 'College Payment';
        break;

      case 'mobile_topup':
        icon = Icons.phone_android;
        color = Colors.green;
        title = 'Mobile Topup';
        break;

      case 'bill_payment':
        icon = Icons.receipt_long;
        color = Colors.red;
        title = 'Bill Payment';
        break;

      case 'shopping':
        icon = Icons.shopping_bag;
        color = Colors.pink;
        title = 'Shopping';
        break;

      default:
        icon = Icons.swap_horiz;
        color = Colors.grey;
        title = 'Transaction';
    }

    return Container(
      key: ValueKey(tx['transaction_id']),
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
