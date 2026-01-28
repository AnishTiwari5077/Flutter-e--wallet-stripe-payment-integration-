// lib/screens/receipt_screen.dart
import 'package:app_wallet/models/transaction_reciept_model.dart';
import 'package:app_wallet/services/pdf_services.dart';
import 'package:flutter/material.dart';
import 'package:app_wallet/services/receipt_service.dart';

class ReceiptScreen extends StatelessWidget {
  final TransactionReceipt receipt;

  const ReceiptScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaction Receipt',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () async {
              // ✅ FIXED: Removed unused pdfFile variable
              // Just call showReceiptOptions which generates PDF internally
              if (context.mounted) {
                await ReceiptService.showReceiptOptions(context, receipt);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),

            // Status
            Text(
              receipt.status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Amount
            Text(
              '\$${receipt.amount.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Transaction Type
            Text(
              receipt.transactionTypeDisplay,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Transaction ID', receipt.transactionId),
                  _buildDetailRow('Date & Time', receipt.formattedDateTime),
                  _buildDetailRow(
                    'Reference',
                    receipt.referenceNumber ?? 'N/A',
                  ),

                  if (receipt.details.isNotEmpty) ...[
                    const Divider(height: 32, color: Colors.white24),
                    const Text(
                      'Payment Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...receipt.details.entries.map((entry) {
                      return _buildDetailRow(entry.key, entry.value ?? 'N/A');
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Balance Card (if available)
            if (receipt.balanceBefore != null && receipt.balanceAfter != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purpleAccent.withOpacity(0.2),
                      Colors.purpleAccent.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Balance Before',
                      '\$${receipt.balanceBefore!.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      'Balance After',
                      '\$${receipt.balanceAfter!.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final pdfFile = await PdfService.generateReceipt(receipt);
                      if (context.mounted) {
                        await ReceiptService.downloadReceipt(context, pdfFile);
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final pdfFile = await PdfService.generateReceipt(receipt);
                      if (context.mounted) {
                        await ReceiptService.shareReceipt(context, pdfFile);
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purpleAccent,
                      side: const BorderSide(color: Colors.purpleAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
