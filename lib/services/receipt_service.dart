// lib/services/receipt_service.dart
import 'dart:io';
import 'package:app_wallet/models/transaction_reciept_model.dart';
import 'package:app_wallet/services/pdf_services.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class ReceiptService {
  /// Generate receipt and show options
  static Future<void> showReceiptOptions(
    BuildContext context,
    TransactionReceipt receipt,
  ) async {
    try {
      // Generate PDF
      final pdfFile = await PdfService.generateReceipt(receipt);

      // Show options dialog
      if (context.mounted) {
        await showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A1A2E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _buildOptionsSheet(context, pdfFile, receipt),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build options bottom sheet
  static Widget _buildOptionsSheet(
    BuildContext context,
    File pdfFile,
    TransactionReceipt receipt,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Receipt Options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // View Receipt
          _buildOptionTile(
            icon: Icons.visibility,
            title: 'View Receipt',
            subtitle: 'Open and preview the receipt',
            onTap: () {
              Navigator.pop(context);
              viewReceipt(context, pdfFile);
            },
          ),

          // Download Receipt
          _buildOptionTile(
            icon: Icons.download,
            title: 'Download Receipt',
            subtitle: 'Save to your device',
            onTap: () async {
              Navigator.pop(context);
              await downloadReceipt(context, pdfFile);
            },
          ),

          // Share Receipt
          _buildOptionTile(
            icon: Icons.share,
            title: 'Share Receipt',
            subtitle: 'Share via email, WhatsApp, etc.',
            onTap: () async {
              Navigator.pop(context);
              await shareReceipt(context, pdfFile);
            },
          ),

          // Print Receipt
          _buildOptionTile(
            icon: Icons.print,
            title: 'Print Receipt',
            subtitle: 'Print using available printer',
            onTap: () async {
              Navigator.pop(context);
              await printReceipt(context, receipt);
            },
          ),

          const SizedBox(height: 16),

          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  /// Build option tile
  static Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purpleAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.purpleAccent),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  /// View receipt in PDF viewer
  static Future<void> viewReceipt(BuildContext context, File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Receipt'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              backgroundColor: const Color(0xFF080814),
              body: PdfPreview(
                build: (format) => bytes,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Download receipt to Downloads folder
  static Future<void> downloadReceipt(
    BuildContext context,
    File pdfFile,
  ) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();

      if (status.isGranted ||
          await Permission.manageExternalStorage.isGranted) {
        // Get Downloads directory
        Directory? downloadsDir;

        if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
        } else {
          downloadsDir = await getApplicationDocumentsDirectory();
        }

        // Create new file in Downloads
        final fileName =
            'ewallet_receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final newFile = File('${downloadsDir.path}/$fileName');

        // Copy file
        await pdfFile.copy(newFile.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Receipt saved to: ${newFile.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () => viewReceipt(context, newFile),
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share receipt via share sheet
  /// ✅ PROPERLY FIXED: Using SharePlus.instance.share() with new API
  static Future<void> shareReceipt(BuildContext context, File pdfFile) async {
    try {
      // Get the box for share position origin (optional but good UX)
      final box = context.findRenderObject() as RenderBox?;

      // Use the NEW SharePlus API
      final shareResult = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(pdfFile.path)],
          text: 'E-Wallet Transaction Receipt',
          subject: 'Transaction Receipt',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        ),
      );

      // Optional: Show result feedback
      if (context.mounted && shareResult.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt shared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Print receipt
  static Future<void> printReceipt(
    BuildContext context,
    TransactionReceipt receipt,
  ) async {
    try {
      final pdfFile = await PdfService.generateReceipt(receipt);
      final bytes = await pdfFile.readAsBytes();

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'receipt_${receipt.transactionId}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Create receipt from transaction data
  static TransactionReceipt createReceiptFromTransaction(
    Map<String, dynamic> transactionData,
    String userName,
    String userEmail,
    String? userPhone,
    double? balanceBefore,
    double? balanceAfter,
  ) {
    return TransactionReceipt(
      transactionId:
          transactionData['transaction_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      transactionType: transactionData['type'] ?? 'transaction',
      dateTime: DateTime.now(),
      amount:
          double.tryParse(transactionData['amount']?.toString() ?? '0') ?? 0.0,
      status: 'Completed',
      senderName: userName,
      senderEmail: userEmail,
      senderPhone: userPhone,
      receiverName: transactionData['receiver_name'],
      receiverPhone: transactionData['receiver_phone'],
      bankName: transactionData['bank_name'],
      accountNumber: transactionData['account_number'],
      collegeName: transactionData['college_name'],
      studentId: transactionData['student_id'],
      semester: transactionData['semester'],
      phoneNumber: transactionData['phone_number'],
      operator: transactionData['operator'],
      billType: transactionData['bill_type'],
      merchantName: transactionData['merchant_name'],
      processingFee: transactionData['processing_fee'],
      totalAmount: transactionData['total_amount'],
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      referenceNumber:
          transactionData['reference_number'] ??
          'REF${DateTime.now().millisecondsSinceEpoch}',
      description: transactionData['description'],
    );
  }
}
