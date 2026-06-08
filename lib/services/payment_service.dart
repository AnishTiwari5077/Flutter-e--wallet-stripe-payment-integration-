import 'package:app_wallet/services/api_services.dart';
//import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentService {
  // Initialize Stripe - call this in main.dart before runApp()
  static void initializeStripe(String publishableKey) {
    Stripe.publishableKey = publishableKey;
  }

  static Future<Map<String, dynamic>> processDepositPayment({
    required double amount,
    required int userId,
  }) async {
    try {
      if (amount <= 0) {
        return {'success': false, 'message': 'Amount must be greater than 0'};
      }

      // Step 1: Create payment intent from backend
      final clientSecret = await ApiService.createPaymentIntent(amount);

      if (clientSecret == null) {
        return {'success': false, 'message': 'Failed to create payment intent'};
      }

      // Step 2: Confirm payment with the card details already entered in CardField
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // Step 3: Update balance in backend after successful payment
      final updateResult = await ApiService.updateBalance(userId, amount);

      if (updateResult['success'] == true) {
        return {
          'success': true,
          'message': updateResult['message'] ?? 'Payment successful!',
          'user': updateResult['user'],
        };
      } else {
        return {
          'success': false,
          'message': updateResult['message'] ?? 'Failed to update balance',
        };
      }
    } on StripeException catch (e) {
      String errorMessage = 'Payment failed';

      if (e.error.code == FailureCode.Canceled) {
        errorMessage = 'Payment cancelled by user';
      } else if (e.error.code == FailureCode.Failed) {
        errorMessage = 'Payment failed. Please try again.';
      } else if (e.error.code == FailureCode.Timeout) {
        errorMessage = 'Payment timeout. Please try again.';
      } else {
        errorMessage = e.error.localizedMessage ?? 'Payment failed';
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // ============================================
  // SEND MONEY
  // ============================================
  static Future<Map<String, dynamic>> sendMoney({
    required int senderId,
    required String receiverPhone,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        return {'success': false, 'message': 'Amount must be greater than 0'};
      }

      //  print('Sending \$$amount from user $senderId to phone $receiverPhone');

      final result = await ApiService.sendMoney(
        senderId,
        receiverPhone,
        amount,
      );

      return result;
    } catch (e) {
      //   print('Send Money Error: $e');
      return {'success': false, 'message': 'Failed to send money: $e'};
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
