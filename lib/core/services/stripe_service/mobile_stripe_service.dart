import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'stripe_service.dart';

class MobileStripeService implements StripeService {
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    Stripe.publishableKey = StripeService.publishableKey;
    await Stripe.instance.applySettings();

    _isInitialized = true;
  }

  Future<Map<String, dynamic>> _createPaymentIntent(int amount, String currency) async {
    final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${StripeService.secretKey}',
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: {
        'amount': amount.toString(),
        'currency': currency,
        'payment_method_types[]': 'card'
      },
    );

    return json.decode(response.body);
  }

  @override
  Future<void> makePayment({
    required int amount,
    required String currency,
    required Function(bool success) onPaymentResult,
    String? priceId,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final paymentIntent = await _createPaymentIntent(amount, currency);
      
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
      rethrow;
    }
  }
} 