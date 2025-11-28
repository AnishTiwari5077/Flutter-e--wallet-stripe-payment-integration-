import 'dart:convert';
import 'package:app_wallet/services/api_services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String backendCreateIntent =
      "${ApiService.baseUrl}/create-payment-intent";

  // amount in cents
  static Future<bool> payWithPaymentSheet({
    required int amountInCents,
    required String userEmail,
  }) async {
    try {
      // 1. create payment intent on backend
      final resp = await http.post(
        Uri.parse(backendCreateIntent),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amountInCents}),
      );

      final body = jsonDecode(resp.body);
      if (resp.statusCode != 200 || body['clientSecret'] == null) {
        throw Exception(body['error'] ?? 'Failed to create intent');
      }

      final clientSecret = body['clientSecret'];

      // 2. init PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Neon Wallet',
        ),
      );

      // 3. present
      await Stripe.instance.presentPaymentSheet();

      // 4. notify backend to update balance
      final update = await ApiService.updateBalance(userEmail, amountInCents);
      return update != null;
    } catch (e) {
      print('Payment error: $e');
      return false;
    }
  }
}
