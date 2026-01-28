// lib/services/pdf_service.dart
import 'dart:io';
import 'package:app_wallet/models/transaction_reciept_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PdfService {
  /// Generate a professional PDF receipt
  static Future<File> generateReceipt(TransactionReceipt receipt) async {
    final pdf = pw.Document();

    // Add page to PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              pw.SizedBox(height: 30),

              // Receipt Title
              _buildTitle(receipt),
              pw.SizedBox(height: 20),

              // Status Badge
              _buildStatusBadge(receipt.status),
              pw.SizedBox(height: 30),

              // Transaction Details
              _buildTransactionDetails(receipt),
              pw.SizedBox(height: 20),

              // Additional Details
              if (receipt.details.isNotEmpty) _buildAdditionalDetails(receipt),

              pw.SizedBox(height: 20),

              // Amount Summary
              _buildAmountSummary(receipt),
              pw.SizedBox(height: 30),

              // Balance Information
              if (receipt.balanceBefore != null && receipt.balanceAfter != null)
                _buildBalanceInfo(receipt),

              pw.Spacer(),

              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    // Save PDF to file
    final output = await _getOutputFile(receipt);
    await output.writeAsBytes(await pdf.save());

    return output;
  }

  /// Build header with logo and app name
  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'E-WALLET',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Transaction Receipt',
                style: const pw.TextStyle(fontSize: 14, color: PdfColors.white),
              ),
            ],
          ),
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Icon(
                const pw.IconData(0xe047), // wallet icon
                size: 40,
                color: PdfColors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build receipt title
  static pw.Widget _buildTitle(TransactionReceipt receipt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          receipt.transactionTypeDisplay,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          receipt.formattedDateTime,
          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Build status badge
  static pw.Widget _buildStatusBadge(String status) {
    final color = status.toLowerCase() == 'completed'
        ? PdfColors.green
        : PdfColors.orange;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: pw.BoxDecoration(
        color: color.shade(0.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
      ),
      child: pw.Text(
        status.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Build transaction details section
  static pw.Widget _buildTransactionDetails(TransactionReceipt receipt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Transaction Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          _buildDetailRow('Transaction ID', receipt.transactionId),
          _buildDetailRow('Reference Number', receipt.referenceNumber ?? 'N/A'),
          _buildDetailRow('Type', receipt.transactionTypeDisplay),
          _buildDetailRow('Date', receipt.formattedDate),
          _buildDetailRow('Time', receipt.formattedTime),
        ],
      ),
    );
  }

  /// Build additional details section
  static pw.Widget _buildAdditionalDetails(TransactionReceipt receipt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          ...receipt.details.entries.map((entry) {
            return _buildDetailRow(entry.key, entry.value ?? 'N/A');
          }),
        ],
      ),
    );
  }

  /// Build amount summary section
  static pw.Widget _buildAmountSummary(TransactionReceipt receipt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        children: [
          if (receipt.processingFee != null) ...[
            _buildAmountRow('Amount', receipt.amount),
            pw.SizedBox(height: 8),
            _buildAmountRow('Processing Fee', receipt.processingFee!),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
          ],
          _buildAmountRow(
            'Total Amount',
            receipt.totalAmount ?? receipt.amount,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// Build balance information section
  static pw.Widget _buildBalanceInfo(TransactionReceipt receipt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Balance Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 10),
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
    );
  }

  /// Build footer with disclaimer
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for using E-Wallet!',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This is a computer-generated receipt and does not require a signature.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'For support, contact: support@ewallet.com',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated on: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Helper: Build detail row
  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper: Build amount row
  static pw.Widget _buildAmountRow(
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.grey800,
          ),
        ),
        pw.Text(
          '\$${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: pw.FontWeight.bold,
            color: isTotal ? PdfColors.purple : PdfColors.grey800,
          ),
        ),
      ],
    );
  }

  /// Get output file path
  static Future<File> _getOutputFile(TransactionReceipt receipt) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'receipt_${receipt.transactionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    return File('${directory.path}/$fileName');
  }
}
