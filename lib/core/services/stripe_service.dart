import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StripeService {
  static String get publishableKey => dotenv.env['NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY'] ?? '';
  static String get secretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  static Future<void> initialize() async {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  static Future<Map<String, dynamic>> createPaymentIntent(int amount, String currency) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount.toString(),
          'currency': currency,
          'payment_method_types[]': 'card',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Ошибка при создании платежа: $e');
    }
  }

  static Future<void> makePayment({
    required int amount,
    required String currency,
    required Function(bool success) onPaymentResult,
  }) async {
    try {
      final paymentIntent = await createPaymentIntent(amount, currency);
      
      final params = SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        merchantDisplayName: 'Tilim App',
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: params,
      );

      await Stripe.instance.presentPaymentSheet();
      
      onPaymentResult(true);
    } catch (e) {
      print('Ошибка при оплате: $e');
      onPaymentResult(false);
    }
  }
} 