import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'stripe_service.dart';

class WebStripeService implements StripeService {
  bool _isInitialized = false;
  bool _isStripeAvailable = false;
  static bool _isScriptLoading = false;
  static DateTime? _lastInitAttempt;

  bool get _isSecureEnvironment {
    final location = html.window.location;
    final isLocalhost = location.hostname == 'localhost' || 
                       location.hostname == '127.0.0.1';
    final isHttps = location.protocol == 'https:';
    
    return isLocalhost || isHttps;
  }

  bool _shouldInitialize() {
    if (_isInitialized) return false;
    if (_isScriptLoading) return false;
    
    if (_lastInitAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastInitAttempt!);
      if (timeSinceLastAttempt.inSeconds < 30) { 
        return false;
      }
    }
    
    return true;
  }

  @override
  Future<void> initialize() async {
    if (!_shouldInitialize()) return;

    _isScriptLoading = true;
    _lastInitAttempt = DateTime.now();

    if (!_isSecureEnvironment) {
      _isStripeAvailable = false;
      _isScriptLoading = false;
      return;
    }

    try {
      final existingScript = html.document.querySelector('script[src="https://js.stripe.com/v3/"]');
      if (existingScript == null) {
        final script = html.ScriptElement()
          ..src = 'https://js.stripe.com/v3/'
          ..type = 'text/javascript'
          ..async = true
          ..defer = true;
        
        script.onError.listen((event) {
          print('Ошибка загрузки Stripe.js');
          _isStripeAvailable = false;
          _isScriptLoading = false;
        });

        html.document.head!.append(script);
        await script.onLoad.first;
      }
      
      _isInitialized = true;
      _isStripeAvailable = true;
    } catch (e) {
      print('Ошибка при инициализации Stripe: $e');
      _isStripeAvailable = false;
    } finally {
      _isScriptLoading = false;
    }
  }

  Future<String> _createCheckoutSession({String? priceId}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('Создание сессии оплаты...');
      
      final url = Uri.parse('https://api.stripe.com/v1/checkout/sessions');
      final origin = html.window.location.origin;
      
      final successUrl = '$origin/#/profile?payment_status=success';
      final cancelUrl = '$origin/#/profile?payment_status=canceled';

      print('Success URL: $successUrl');
      print('Cancel URL: $cancelUrl');

      final selectedPriceId = priceId ?? StripeService.MONTHLY_PLAN_ID;

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${StripeService.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
          'mode': 'subscription',
          'success_url': successUrl,
          'cancel_url': cancelUrl,
          'line_items[0][price]': selectedPriceId,
          'line_items[0][quantity]': '1',
        },
      );

      if (response.statusCode == 200) {
        final sessionData = json.decode(response.body);
        return sessionData['url'];
      } else {
        throw Exception('Ошибка создания сессии оплаты: ${response.body}');
      }
    } catch (e) {
      print('Ошибка при создании сессии: $e');
      rethrow;
    }
  }

  @override
  Future<void> makePayment({
    required int amount,
    required String currency,
    required Function(bool success) onPaymentResult,
    String? priceId,
  }) async {
    try {
      print('Начало процесса оплаты...');
      print('Сумма: $amount $currency');
      print('PriceId: $priceId');
      
      if (!_isSecureEnvironment) {
        print('Небезопасное окружение, требуется HTTPS');
        throw Exception('Требуется HTTPS соединение');
      }

      if (!_isInitialized) {
        print('Stripe не инициализирован, выполняем инициализацию...');
        await initialize();
      }

      if (!_isStripeAvailable) {
        print('Stripe недоступен после инициализации');
        throw Exception('Stripe не инициализирован');
      }

      print('Создаем сессию оплаты...');
      final checkoutUrl = await _createCheckoutSession(priceId: priceId);
      
      print('Перенаправляем на страницу оплаты: $checkoutUrl');
      html.window.location.href = checkoutUrl;
      
      onPaymentResult(true);
    } catch (e) {
      print('Ошибка при оплате: $e');
      onPaymentResult(false);
      rethrow;
    }
  }

  bool isStripeAvailable() {
    print('Проверка доступности Stripe: $_isStripeAvailable');
    return _isStripeAvailable;
  }
}

class SecureConnectionException implements Exception {
  final String message;
  final String httpsUrl;

  SecureConnectionException(this.message, this.httpsUrl);

  @override
  String toString() => message;
} 