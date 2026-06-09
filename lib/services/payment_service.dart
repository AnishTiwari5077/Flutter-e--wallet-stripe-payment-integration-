import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentService {
  // Initialize Stripe - call this in main.dart before runApp()
  static Future<void> initializeStripe(String publishableKey) async {
    try {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      debugPrint('Stripe initialization failed: $e');
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  // Validate amount string
  static bool validateAmount(String amountText) {
    if (amountText.isEmpty) return false;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return false;

    return true;
  }

  // Format currency
  static String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Parse amount from string
  static double? parseAmount(String amountText) {
    try {
      return double.parse(amountText);
    } catch (e) {
      return null;
    }
  }

  // Convert dollars to cents (if needed for display)
  static int dollarsToCents(double dollars) {
    return (dollars * 100).round();
  }

  // Convert cents to dollars (if needed for display)
  static double centsToDollars(int cents) {
    return cents / 100.0;
  }
}
