import 'dart:convert';
import '../../../config/app_config.dart';
import '../../../core/services/http_service.dart';

class SubscriptionService {
  final HttpService _httpService = HttpService();

  Future<String?> getStripeCheckoutUrl() async {
    try {
      final response = await _httpService.post(
        '${AppConfig.baseUrl}/subscriptions/create-checkout-session',
        body: jsonEncode({}),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      print('Ошибка при получении URL оплаты: $e');
      return null;
    }
  }

  Future<bool> purchaseSubscription(DateTime expiresAt) async {
    try {
      final bodyMap = {
        'expires_at': '${expiresAt.year}-${expiresAt.month.toString().padLeft(2, '0')}-${expiresAt.day.toString().padLeft(2, '0')}',
      };

      final body = jsonEncode(bodyMap);

      print('Отправляем запрос на покупку подписки:');
      print('URL: ${AppConfig.baseUrl}/subscriptions/purchase');
      print('Body: $body');

      final response = await _httpService.post(
        '${AppConfig.baseUrl}/subscriptions/purchase',
        body: body,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Charset': 'utf-8',
        },
      );

      print('Ответ сервера: ${response.statusCode} - ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка при покупке подписки: $e');
      throw Exception('Ошибка при покупке подписки: $e');
    }
  }
}
