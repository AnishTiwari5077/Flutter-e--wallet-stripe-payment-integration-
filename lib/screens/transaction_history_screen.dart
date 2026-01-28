import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_wallet/providers/auth_provider.dart';
import 'package:app_wallet/providers/transaction_provider.dart';
import 'package:app_wallet/services/receipt_service.dart';
import 'package:app_wallet/screens/receipt_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user?.id != null) {
        context.read<TransactionProvider>().fetchUserTransactions(
          auth.user!.id!,
        );
      }
    });
  }

  List<dynamic> _filterTransactions(List<dynamic> transactions, int userId) {
    if (_filterType == 'all') return transactions;

    return transactions.where((tx) {
      final type = tx['type'] ?? '';
      final isSent = tx['sender_id'] == userId;

      switch (_filterType) {
        case 'send':
          return isSent && type == 'send';
        case 'receive':
          return !isSent && type == 'send';
        case 'deposit':
          return type == 'add';
        case 'bank_transfer':
          return type == 'bank_transfer';
        case 'college':
          return type == 'college_payment';
        case 'topup':
          return type == 'mobile_topup';
        case 'bills':
          return type == 'bill_payment';
        case 'shopping':
          return type == 'shopping';
        default:
          return true;
      }
    }).toList();
  }

  // ✅ NEW METHOD: Show receipt for a transaction
  Future<void> _showTransactionReceipt(dynamic tx) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;

      if (user == null) return;

      // Create receipt from transaction data
      final receipt = ReceiptService.createReceiptFromTransaction(
        tx,
        user.name,
        user.email,
        user.phone,
        null, // Balance before (not available for historical transactions)
        null, // Balance after (not available for historical transactions)
      );

      // Navigate to receipt screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReceiptScreen(receipt: receipt)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF080814),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Transaction History'),
        ),
        body: const Center(
          child: Text(
            'Please login to view transactions',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final filteredTransactions = _filterTransactions(
      transactionProvider.transactions,
      user.id!,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              transactionProvider.refreshTransactions(user.id!);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Sent', 'send'),
                const SizedBox(width: 8),
                _buildFilterChip('Received', 'receive'),
                const SizedBox(width: 8),
                _buildFilterChip('Deposit', 'deposit'),
                const SizedBox(width: 8),
                _buildFilterChip('Bank Transfer', 'bank_transfer'),
                const SizedBox(width: 8),
                _buildFilterChip('College', 'college'),
                const SizedBox(width: 8),
                _buildFilterChip('Topup', 'topup'),
                const SizedBox(width: 8),
                _buildFilterChip('Bills', 'bills'),
                const SizedBox(width: 8),
                _buildFilterChip('Shopping', 'shopping'),
              ],
            ),
          ),

          Expanded(
            child: transactionProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 80,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        transactionProvider.refreshTransactions(user.id!),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(
                          filteredTransactions[index],
                          user.id!,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.purpleAccent
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.purpleAccent
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic tx, int userId) {
    final type = tx['type'] ?? '';
    final amount = double.tryParse('${tx['amount']}') ?? 0.0;
    final date = tx['created_at'] ?? '';
    final isSent = tx['sender_id'] == userId;

    IconData icon;
    Color color;
    String title;
    String subtitle = '';

    switch (type) {
      case 'add':
        icon = Icons.add_circle;
        color = Colors.green;
        title = 'Deposit';
        subtitle = 'Added to wallet';
        break;
      case 'send':
        if (isSent) {
          icon = Icons.arrow_upward;
          color = Colors.red;
          title = 'Sent to ${tx['receiver_name'] ?? 'Unknown'}';
          subtitle = tx['receiver_phone'] ?? '';
        } else {
          icon = Icons.arrow_downward;
          color = Colors.green;
          title = 'Received from ${tx['sender_name'] ?? 'Unknown'}';
          subtitle = tx['sender_phone'] ?? '';
        }
        break;
      case 'bank_transfer':
        icon = Icons.account_balance;
        color = Colors.blue;
        title = 'Bank Transfer';
        subtitle = 'To bank account';
        break;
      case 'college_payment':
        icon = Icons.school;
        color = Colors.orange;
        title = 'College Payment';
        subtitle = 'Tuition fee';
        break;
      case 'mobile_topup':
        icon = Icons.phone_android;
        color = Colors.green;
        title = 'Mobile Topup';
        subtitle = 'Recharge';
        break;
      case 'bill_payment':
        icon = Icons.receipt_long;
        color = Colors.red;
        title = 'Bill Payment';
        subtitle = 'Utility bill';
        break;
      case 'shopping':
        icon = Icons.shopping_bag;
        color = Colors.pink;
        title = 'Shopping';
        subtitle = 'Purchase';
        break;
      default:
        icon = Icons.swap_horiz;
        color = Colors.grey;
        title = 'Transaction';
        subtitle = type;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),

          // Amount and Receipt Button Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount
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
              const SizedBox(height: 8),

              // ✅ RECEIPT BUTTON
              InkWell(
                onTap: () => _showTransactionReceipt(tx),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.purpleAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt, size: 14, color: Colors.purpleAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Receipt',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
